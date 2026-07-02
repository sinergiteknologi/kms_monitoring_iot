import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kms_monitoring_iot/core/app_globals.dart';
import 'package:kms_monitoring_iot/page/connect/connect_viewmodel.dart';
import 'package:kms_monitoring_iot/service/api_services.dart';
import 'package:stacked/stacked.dart';

class HistoryViewModel extends FutureViewModel {
  final ApiServices _apiServices = ApiServices();
  String? _baseUrl;
  String? errorMessage;

  List<Map<String, dynamic>> _rawFopList = [];
  List<Map<String, dynamic>> fopList = [];

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String? selectedCategory;
  String? selectedProcessName;

  List<String> get availableCategories {
    final cats = <String>{};
    for (final fop in _rawFopList) {
      for (final bom in (fop['BOMList'] as List? ?? [])) {
        final cat = (bom as Map)['Category']?.toString() ?? '';
        if (cat.isNotEmpty) cats.add(cat);
      }
    }
    return cats.toList()..sort();
  }

  List<String> get availableProcessNames {
    final names = <String>{};
    for (final fop in _rawFopList) {
      for (final bom in (fop['BOMList'] as List? ?? [])) {
        for (final p in ((bom as Map)['ProcessList'] as List? ?? [])) {
          final name = (p as Map)['ProcessName']?.toString() ?? '';
          if (name.isNotEmpty) names.add(name);
        }
      }
    }
    return names.toList()..sort();
  }

  void setSearchQuery(String q) {
    _searchQuery = q.trim().toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    selectedCategory = null;
    selectedProcessName = null;
    fopList = List.from(_rawFopList);
    notifyListeners();
  }

  void setCategory(String? cat) {
    selectedCategory = cat;
    _applyFilter();
    notifyListeners();
  }

  void setProcessName(String? name) {
    selectedProcessName = name;
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    var filtered = _rawFopList;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((fop) {
        final headerMatch = fop.entries
            .where((e) => e.key != 'BOMList')
            .any(
              (e) => e.value.toString().toLowerCase().contains(_searchQuery),
            );
        if (headerMatch) return true;

        final boms = fop['BOMList'] as List? ?? [];
        return boms.any((bom) {
          final b = bom as Map;
          final bomMatch = b.entries
              .where((e) => e.key != 'ProcessList')
              .any(
                (e) => e.value.toString().toLowerCase().contains(_searchQuery),
              );
          if (bomMatch) return true;
          return (b['ProcessList'] as List? ?? []).any(
            (p) => (p as Map).values.any(
              (v) => v.toString().toLowerCase().contains(_searchQuery),
            ),
          );
        });
      }).toList();
    }

    if (selectedCategory != null || selectedProcessName != null) {
      filtered = filtered
          .map((fop) {
            final boms = (fop['BOMList'] as List? ?? [])
                .cast<Map<String, dynamic>>()
                .where((bom) {
                  if (selectedCategory != null &&
                      bom['Category']?.toString() != selectedCategory) {
                    return false;
                  }
                  if (selectedProcessName != null) {
                    final processes = bom['ProcessList'] as List? ?? [];
                    if (!processes.any(
                      (p) =>
                          (p as Map)['ProcessName']?.toString() ==
                          selectedProcessName,
                    )) {
                      return false;
                    }
                  }
                  return true;
                })
                .toList();
            return {...fop, 'BOMList': boms};
          })
          .where((fop) => (fop['BOMList'] as List).isNotEmpty)
          .toList();
    }

    fopList = filtered;
  }

  Future<String?> _getBaseUrl() async {
    if (_baseUrl != null) return _baseUrl;

    final savedIp = await ConnectViewModel.getSavedIp();
    if (savedIp == null || savedIp.trim().isEmpty) return null;

    _baseUrl = _normalizeBaseUrl(savedIp);
    return _baseUrl;
  }

  String _normalizeBaseUrl(String value) {
    var url = value.trim();
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.contains(':')) {
      return 'http://$url';
    }
    return 'http://$url:1346';
  }

  Future<List<Map<String, dynamic>>> _fetchCountingFinish() async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) {
      errorMessage = 'IP server belum tersimpan';
      return [];
    }

    final uri = Uri.parse('$baseUrl/ApiKMS/api/getCountingFinish').replace(
      queryParameters: {'AccountID': AppGlobals.accountID},
    );

    debugPrint('fetchHistory getCountingFinish: $uri');

    final response = await http
        .get(uri, headers: {'Content-Type': 'application/json'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('getCountingFinish gagal (${response.statusCode})');
    }

    return _extractList(response.body);
  }

  List<String> _extractFopNumbers(List<Map<String, dynamic>> finishItems) {
    final fops = <String>{};
    for (final item in finishItems) {
      final raw =
          item['RefNumber'] ?? item['FOPNumber'] ?? item['FopNumber'];
      final fop = raw?.toString().trim() ?? '';
      if (fop.isNotEmpty) fops.add(fop);
    }
    return fops.toList()..sort();
  }

  List<Map<String, dynamic>> _extractList(String body) {
    if (body.trim().isEmpty) return [];

    final decoded = jsonDecode(body);
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (decoded is Map) {
      final data = decoded['data'] ?? decoded['Data'] ?? decoded['result'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }

    return [];
  }

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

  Future<void> fetchHistory() async {
    setBusy(true);
    errorMessage = null;

    try {
      final finishItems = await _fetchCountingFinish();
      final fopNumbers = _extractFopNumbers(finishItems);

      debugPrint(
        'fetchHistory: ${finishItems.length} finish, '
        '${fopNumbers.length} FOP unik',
      );

      if (fopNumbers.isEmpty) {
        _rawFopList = [];
        fopList = [];
        notifyListeners();
        return;
      }

      final decoded = await _apiServices.postRaw(
        '/getDataHistoryProcess',
        {'FOPNumber': fopNumbers},
      );

      List<dynamic> rawList = [];
      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map && decoded['data'] is List) {
        rawList = decoded['data'] as List;
      }

      final allItems = rawList
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      _rawFopList = _parseGroupedFopList(allItems);
      _rawFopList.sort((a, b) {
        final na = a['FOPNumber']?.toString() ?? '';
        final nb = b['FOPNumber']?.toString() ?? '';
        return nb.compareTo(na);
      });

      _applyFilter();
      notifyListeners();

      debugPrint('fetchHistory: ${_rawFopList.length} FOP history loaded');
    } catch (e) {
      errorMessage = 'Gagal memuat history';
      debugPrint('fetchHistory error: $e');
      _rawFopList = [];
      fopList = [];
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  @override
  Future<void> futureToRun() async {
    await fetchHistory();
  }
}
