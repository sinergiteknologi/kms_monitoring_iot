import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kms_monitoring_iot/core/app_globals.dart';
import 'package:kms_monitoring_iot/page/connect/connect_viewmodel.dart';
import 'package:kms_monitoring_iot/service/api_services.dart';
import 'package:stacked/stacked.dart';
import 'package:intl/intl.dart';

class TaskListViewModel extends FutureViewModel {
  final ApiServices _apiServices = ApiServices();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController inputProduk = TextEditingController();
  final TextEditingController fopPlanning = TextEditingController();
  final TextEditingController inputKodeMesin = TextEditingController();
  final TextEditingController inputCount = TextEditingController();
  final TextEditingController countingFormula = TextEditingController();
  bool? isStart;

  // Gunakan taskList dari AppGlobals agar bisa diakses file lain
  List<Map<String, dynamic>> get taskList => AppGlobals.taskList;

  // Variabel untuk data FOP (Level 1-2-3) — terpisah dari taskList
  List<Map<String, dynamic>> fopList = [];
  List<Map<String, dynamic>> _rawFopList = []; // data asli sebelum filter

  // ── Filter ──────────────────────────────────────────────────
  String? selectedCategory;
  String? selectedProcessName;

  /// Semua kategori unik dari data
  List<String> get availableCategories {
    final Set<String> cats = {};
    for (final fop in _rawFopList) {
      final boms = fop['BOMList'] as List? ?? [];
      for (final bom in boms) {
        final cat = bom['Category']?.toString() ?? '';
        if (cat.isNotEmpty) cats.add(cat);
      }
    }
    return cats.toList()..sort();
  }

  /// Semua ProcessName unik dari data
  List<String> get availableProcessNames {
    final Set<String> names = {};
    for (final fop in _rawFopList) {
      final boms = fop['BOMList'] as List? ?? [];
      for (final bom in boms) {
        final processes = bom['ProcessList'] as List? ?? [];
        for (final p in processes) {
          final name = p['ProcessName']?.toString() ?? '';
          if (name.isNotEmpty) names.add(name);
        }
      }
    }
    return names.toList()..sort();
  }

  void setCategory(String? category) {
    selectedCategory = category;
    _applyFilter();
    notifyListeners();
  }

  void setProcessName(String? processName) {
    selectedProcessName = processName;
    _applyFilter();
    notifyListeners();
  }

  void clearFilters() {
    selectedCategory = null;
    selectedProcessName = null;
    fopList = List.from(_rawFopList);
    notifyListeners();
  }

  void _applyFilter() {
    if (selectedCategory == null && selectedProcessName == null) {
      fopList = List.from(_rawFopList);
      return;
    }

    fopList = _rawFopList
        .map((fop) {
          final boms = (fop['BOMList'] as List? ?? [])
              .map((b) => Map<String, dynamic>.from(b as Map))
              .where((bom) {
                // Filter kategori
                if (selectedCategory != null) {
                  if (bom['Category']?.toString() != selectedCategory)
                    return false;
                }
                // Filter process name
                if (selectedProcessName != null) {
                  final processes = bom['ProcessList'] as List? ?? [];
                  final hasProcess = processes.any(
                    (p) => p['ProcessName']?.toString() == selectedProcessName,
                  );
                  if (!hasProcess) return false;
                }
                return true;
              })
              .toList();

          return {...fop, 'BOMList': boms};
        })
        .where((fop) {
          final boms = fop['BOMList'] as List? ?? [];
          return boms.isNotEmpty;
        })
        .toList();
  }

  Timer? _autoRefreshTimer;
  static const Duration _refreshInterval = Duration(seconds: 10);
  bool isRunning = false; // true = timer sedang berjalan

  /// Mulai auto-refresh: setiap 10 detik loop semua item taskList,
  /// hit getCounting per SensorID, update data, dan persist ke SharedPreferences
  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    isRunning = true;
    notifyListeners();
    _autoRefreshTimer = Timer.periodic(_refreshInterval, (_) async {
      await _refreshAllTasks();
    });
    debugPrint(
      'Auto-refresh started (interval: ${_refreshInterval.inSeconds}s)',
    );
  }

  /// Hentikan auto-refresh
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    isRunning = false;
    // Stop juga timer di OngoingViewModel
    AppGlobals.stopOngoingTimer();
    notifyListeners();
    debugPrint('Auto-refresh stopped');
  }

  /// Loop semua item di taskList, hit API getCounting per SensorID,
  /// update field yang berubah, lalu persist ke SharedPreferences
  Future<void> _refreshAllTasks() async {
    if (AppGlobals.taskList.isEmpty) return;

    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) return;

    bool hasUpdate = false;
    final List<int> indexesToRemove = [];

    for (int i = 0; i < AppGlobals.taskList.length; i++) {
      final item = AppGlobals.taskList[i];
      final sensorID = item['SensorID']?.toString() ?? '';
      if (sensorID.isEmpty) continue;

      try {
        final uri = Uri.parse('$baseUrl/ApiKMS/api/getCounting').replace(
          queryParameters: {
            'AccountID': AppGlobals.accountID,
            'ObjectID': AppGlobals.objectID,
            'SensorID': sensorID,
          }.map((k, v) => MapEntry(k, v.toString())),
        );

        final response = await http
            .get(uri, headers: {'Content-Type': 'application/json'})
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body) as Map<String, dynamic>;
          if (result['success'] == true && result['data'] != null) {
            final data = result['data'] as List<dynamic>;
            if (data.isNotEmpty) {
              // Update item dengan data terbaru dari server
              AppGlobals.taskList[i] = Map<String, dynamic>.from(
                data.first as Map,
              );
              hasUpdate = true;
              debugPrint('Refreshed SensorID $sensorID');
            } else {
              // Data kosong dari server → SensorID sudah tidak ongoing
              // tandai untuk dihapus dari taskList
              indexesToRemove.add(i);
              debugPrint(
                'SensorID $sensorID tidak ada di server, hapus dari taskList',
              );
            }
          } else {
            // success false atau data null → sudah tidak ongoing
            indexesToRemove.add(i);
            debugPrint('SensorID $sensorID sudah selesai, hapus dari taskList');
          }
        }
      } catch (e) {
        debugPrint('Refresh error SensorID $sensorID: $e');
      }
    }

    // Hapus dari belakang agar index tidak bergeser
    for (final i in indexesToRemove.reversed) {
      AppGlobals.taskList.removeAt(i);
      hasUpdate = true;
    }

    if (hasUpdate) {
      // Persist ke SharedPreferences dan notify UI
      AppGlobals.taskList = AppGlobals.taskList;
      // Trigger OngoingView untuk refresh dari API
      AppGlobals.triggerOngoingRefresh();
      notifyListeners();
    }

    // Jika taskList sudah kosong, hentikan timer
    if (AppGlobals.taskList.isEmpty) {
      stopAutoRefresh();
    }
  }

  String? _baseUrl;
  StreamSubscription<int>? _taskCountSubscription;

  TaskListViewModel() {
    searchController.addListener(() => notifyListeners());
    // Pantau perubahan taskList dari mana pun —
    // jika kosong dan timer masih jalan, hentikan otomatis
    _taskCountSubscription = AppGlobals.taskCountStream.listen((count) {
      if (count == 0 && isRunning) {
        stopAutoRefresh();
      }
    });
  }

  /// Dipanggil saat viewmodel ready — restart timer jika taskList masih ada
  /// (kasus app dibuka ulang setelah force close)
  void resumeTimerIfNeeded() {
    if (AppGlobals.taskList.isNotEmpty && !isRunning) {
      debugPrint(
        'taskList ada ${AppGlobals.taskList.length} item, resume timer...',
      );
      AppGlobals.startOngoingTimer();
      startAutoRefresh();
    } else if (AppGlobals.taskList.isEmpty) {
      debugPrint('taskList kosong, timer tidak dijalankan');
    } else {
      debugPrint('Timer sudah berjalan, skip resume');
    }
  }

  bool get hasSearchText => searchController.text.isNotEmpty;

  void clearSearch() {
    searchController.clear();
  }

  /// Format DateTime ke string PostgreSQL timestamp
  /// Output: "2026-04-24 15:15:52.199330"
  String formatTimestamp(DateTime dt) {
    return DateFormat('yyyy-MM-dd HH:mm:ss.SSSSSS').format(dt);
  }

  /// Shortcut untuk timestamp sekarang
  String get nowTimestamp => formatTimestamp(DateTime.now());

  /// Ambil base URL dari IP/URL yang tersimpan di SharedPreferences.
  /// Support:
  /// - 192.168.1.10
  /// - 192.168.1.10:1346
  /// - http://192.168.1.10:1346
  ///
  Future<String?> _getBaseUrl() async {
    if (_baseUrl != null) return _baseUrl;

    final saved = await ConnectViewModel.getSavedIp();
    if (saved == null || saved.trim().isEmpty) return null;

    var value = saved.trim();

    if (value.startsWith('http://') || value.startsWith('https://')) {
      _baseUrl = value.endsWith('/')
          ? value.substring(0, value.length - 1)
          : value;
    } else {
      final hasPort = RegExp(r':\d+$').hasMatch(value);
      _baseUrl = 'http://$value${hasPort ? '' : ':1346'}';
    }

    debugPrint('Base URL ApiKMS: $_baseUrl');
    return _baseUrl;
  }

  /// GET /ApiKMS/api/getCounting?AccountID=KMS&SensorID={sensorID}
  /// SensorID diambil dari inputKodeMesin, bisa juga di-override lewat parameter
  Future<void> getCounting({
    String accountID = 'KMS',
    String? objectID,
    String? sensorID,
  }) async {
    // Jika taskList sudah ada data, tidak perlu fetch ulang dari server
    if (AppGlobals.taskList.isNotEmpty) {
      notifyListeners();
      return;
    }

    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) {
      debugPrint('getCounting error: IP tidak tersimpan');
      return;
    }

    final sid = sensorID ?? inputKodeMesin.text.trim();

    setBusy(true);
    try {
      final uri = Uri.parse('$baseUrl/ApiKMS/api/getCounting').replace(
        queryParameters: {
          'AccountID': accountID,
          if (objectID != null && objectID.isNotEmpty) 'ObjectID': objectID,
          if (sid.isNotEmpty) 'SensorID': sid,
        },
      );

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      debugPrint('getCounting status: ${response.statusCode}');
      debugPrint('getCounting body: ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;

        if (result['success'] == true && result['data'] != null) {
          AppGlobals.taskList = List<Map<String, dynamic>>.from(
            (result['data'] as List).map((e) => Map<String, dynamic>.from(e)),
          );
          debugPrint('getCounting total: ${result['total']}');
        } else {
          AppGlobals.clearTaskList();
          debugPrint('getCounting message: ${result['message']}');
        }
        notifyListeners();
      } else {
        debugPrint('getCounting failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('getCounting error: $e');
    } finally {
      setBusy(false);
    }
  }

  /// Group flat rows: FOPNumber → BOMCode → ProcessList
  List<Map<String, dynamic>> _parseGroupedFopList(
    List<Map<String, dynamic>> allItems,
  ) {
    final fopOrder = <String>[];
    final fopHeaders = <String, Map<String, dynamic>>{};
    final bomOrder = <String, List<String>>{};
    final bomData = <String, Map<String, Map<String, dynamic>>>{};

    for (final item in allItems) {
      final fopNum = item['FOPNumber']?.toString().trim() ?? '';
      final bomCode = item['BOMCode']?.toString().trim() ?? '';
      if (fopNum.isEmpty) continue;

      if (!fopHeaders.containsKey(fopNum)) {
        fopOrder.add(fopNum);
        fopHeaders[fopNum] = {
          'FOPNumber': fopNum,
          'FOPDate': item['FOPDate'],
          'SONumber': item['SONumber'],
          'Description': item['Description'],
        };
        bomOrder[fopNum] = [];
        bomData[fopNum] = {};
      }

      if (bomCode.isEmpty) continue;

      if (!bomData[fopNum]!.containsKey(bomCode)) {
        bomOrder[fopNum]!.add(bomCode);
        bomData[fopNum]![bomCode] = {
          'FOPNumber': fopNum,
          'BOMCode': bomCode,
          'BOMName': item['BOMName'],
          'QTY': item['QTY'],
          'Category': item['Category'],
          'ProcessList': <Map<String, dynamic>>[],
        };
      }

      final processCode = item['ProcessCode']?.toString().trim() ?? '';
      if (processCode.isEmpty) continue;

      final processes =
          bomData[fopNum]![bomCode]!['ProcessList'] as List<Map<String, dynamic>>;
      final exists = processes.any(
        (p) => p['ProcessCode']?.toString() == processCode,
      );
      if (!exists) {
        processes.add({
          'FOPNumber': fopNum,
          'BOMCode': bomCode,
          'ProcessCode': item['ProcessCode'],
          'ProcessName': item['ProcessName'],
        });
      }
    }

    return fopOrder.map((fopNum) {
      final boms = bomOrder[fopNum]!
          .map((bomCode) => bomData[fopNum]![bomCode]!)
          .toList();
      return {...fopHeaders[fopNum]!, 'BOMList': boms};
    }).toList();
  }

  /// GET /api/mobile/getDataAllFOP
  /// Response flat: setiap baris = FOP + BOM + Process
  Future<void> getDataProcess() async {
    setBusy(true);
    try {
      final decoded = await _apiServices.getRaw('/getDataAllFOP');

      List<dynamic> rawList = [];
      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map && decoded['data'] is List) {
        rawList = decoded['data'] as List;
      }

      final allItems = rawList
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      fopList = _parseGroupedFopList(allItems);
      _rawFopList = List.from(fopList);
      _applyFilter();

      final bomCount = fopList.fold<int>(
        0,
        (sum, fop) => sum + ((fop['BOMList'] as List?)?.length ?? 0),
      );
      debugPrint(
        'getDataProcess: ${fopList.length} FOP, $bomCount BOM',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('getDataProcess error: $e');
    } finally {
      setBusy(false);
    }
  }

  /// GET data FOP 3 level (FOP → BOM → Process)
  /// Endpoint: /ApiKMS/api/getFOPList?AccountID=KMS&FOPNumber={fopNumber}
  Future<void> getFopList({String? fopNumber}) async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) {
      debugPrint('getFopList error: IP tidak tersimpan');
      return;
    }

    setBusy(true);
    try {
      final queryParams = <String, String>{
        'AccountID': AppGlobals.accountID.isNotEmpty
            ? AppGlobals.accountID
            : 'KMS',
      };
      if (fopNumber != null && fopNumber.isNotEmpty) {
        queryParams['FOPNumber'] = fopNumber;
      }

      final uri = Uri.parse(
        '$baseUrl/ApiKMS/api/getFOPList',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      debugPrint('getFopList status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body) as Map<String, dynamic>;
        if (result['success'] == true && result['data'] != null) {
          fopList = List<Map<String, dynamic>>.from(
            (result['data'] as List).map((e) => Map<String, dynamic>.from(e)),
          );
          debugPrint('getFopList total: ${fopList.length}');
        } else {
          fopList = [];
          debugPrint('getFopList message: ${result['message']}');
        }
        notifyListeners();
      } else {
        debugPrint('getFopList failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('getFopList error: $e');
    } finally {
      setBusy(false);
    }
  }

  // Error message untuk validasi field
  String? errorFopPlanning;
  String? errorKodeMesin;
  String? errorCountingFormula;

  num? _parseCountingFormulaValue(String value) {
    final normalized = value.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return num.tryParse(normalized);
  }

  /// Validasi field — return true jika valid
  bool _validateFields() {
    final formulaText = countingFormula.text.trim();

    errorFopPlanning = fopPlanning.text.trim().isEmpty
        ? 'FOP Planning tidak boleh kosong'
        : null;

    errorKodeMesin = inputKodeMesin.text.trim().isEmpty
        ? 'Process ID tidak boleh kosong'
        : null;

    if (formulaText.isEmpty) {
      errorCountingFormula = 'Counting Formula tidak boleh kosong';
    } else if (_parseCountingFormulaValue(formulaText) == null) {
      errorCountingFormula = 'Counting Formula harus berupa angka';
    } else {
      errorCountingFormula = null;
    }

    notifyListeners();
    return errorFopPlanning == null &&
        errorKodeMesin == null &&
        errorCountingFormula == null;
  }

  Future<bool> postCounting(BuildContext ctx) async {
    if (!_validateFields()) return false;

    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) {
      debugPrint('postCounting error: IP tidak tersimpan');
      return false;
    }

    setBusy(true);
    try {
      final processId = inputKodeMesin.text.trim();
      final refNumber = fopPlanning.text.trim();
      final formulaValue = _parseCountingFormulaValue(countingFormula.text);
      if (formulaValue == null) {
        errorCountingFormula = 'Counting Formula harus berupa angka';
        notifyListeners();
        return false;
      }
      await getDataProcess();

      final body = {
        'AccountID': AppGlobals.accountID.isNotEmpty
            ? AppGlobals.accountID
            : 'KMS',
        'ObjectID': AppGlobals.objectID.isNotEmpty
            ? AppGlobals.objectID
            : 'KMS',

        // Logic ApiKMS: Process ID dari input/scan Process ID.
        // SensorID juga dikirim memakai processId supaya kompatibel jika endpoint lama membaca SensorID.
        'SensorID': processId,
        'ProcesID': processId,
        'RefNumber': refNumber,
        // Payload tambahan sesuai request.
        'Product': inputProduk.text,
        'CountingFormula': formulaValue,
        'StartDate': nowTimestamp,
        'EndDate': null,
        'TotalCount': 0,
        'CountValue': 0,
        'AdjustValue': 0,
        'StartCount': 0,
        'CurrentCount': 0,
      };

      final uri = Uri.parse('$baseUrl/ApiKMS/api/postCounting');

      debugPrint('postCounting uri: $uri');
      debugPrint('postCounting body: ${jsonEncode(body)}');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('postCounting status: ${response.statusCode}');
      debugPrint('postCounting body: ${response.body}');

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          result['success'] == true) {
        final savedData = result['data'] != null
            ? Map<String, dynamic>.from(result['data'] as Map)
            : Map<String, dynamic>.from(body);

        await AppGlobals.addTask(savedData);

        inputProduk.clear();
        inputKodeMesin.clear();
        fopPlanning.clear();
        inputCount.clear();
        countingFormula.clear();

        if (ctx.mounted) FocusScope.of(ctx).unfocus();

        AppGlobals.triggerOngoingRefresh();
        AppGlobals.startOngoingTimer();
        startAutoRefresh();

        notifyListeners();
        debugPrint('postCounting success: ${result['message']}');
        return true;
      } else {
        debugPrint('postCounting failed: ${result['message']}');
        return false;
      }
    } catch (e) {
      debugPrint('postCounting error: $e');
      return false;
    } finally {
      setBusy(false);
    }
  }

  void addToList(BuildContext ctx) {
    taskList.add({
      'RefNumber': fopPlanning.text,
      'SensorID': inputKodeMesin.text,
      'Count': inputCount.text,
    });
    inputProduk.clear();
    inputKodeMesin.clear();
    inputCount.clear();
    countingFormula.clear();
    FocusScope.of(ctx).unfocus();
    notifyListeners();
  }

  void onEdit(Map<String, dynamic> e) {
    inputProduk.text = e['ProdCode'] ?? '';
    inputKodeMesin.text = e['MachineCode'] ?? '';
    inputCount.text = e['Count']?.toString() ?? '';
    countingFormula.text = e['CountingFormula']?.toString() ?? '';
    taskList.remove(e);
    notifyListeners();
  }

  @override
  void dispose() {
    stopAutoRefresh();
    _taskCountSubscription?.cancel();
    searchController.dispose();
    inputProduk.dispose();
    fopPlanning.dispose();
    inputKodeMesin.dispose();
    inputCount.dispose();
    countingFormula.dispose();
    super.dispose();
  }

  @override
  Future<void> futureToRun() async {
    await getDataProcess();
  }
}
