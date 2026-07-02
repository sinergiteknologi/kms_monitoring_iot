import 'package:flutter/material.dart';
import 'package:kms_monitoring_iot/core/app_globals.dart';
import 'package:kms_monitoring_iot/service/api_services.dart';
import 'package:stacked/stacked.dart';

class HistoryViewModel extends FutureViewModel {
  List<Map<String, dynamic>> _rawFopList = [];
  List<Map<String, dynamic>> fopList = [];

  // ── Search ───────────────────────────────────────────────────
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

    // Search text
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((fop) {
        // Cocokkan di semua field header FOP
        final headerMatch = fop.entries
            .where((e) => e.key != 'BOMList')
            .any(
              (e) => e.value.toString().toLowerCase().contains(_searchQuery),
            );
        if (headerMatch) return true;
        // Cocokkan di BOM / Process
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

    // Filter kategori / process
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
                    ))
                      return false;
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

  Future<void> fetchHistory() async {
    setBusy(true);
    try {
      // Gunakan POST /getDataHistoryProcess sama seperti getDataProcess di task_list
      // tapi tanpa filter FOPNumber agar return semua history
      final apiServices = ApiServices();
      final decoded = await apiServices.postRaw('/getDataHistoryProcess', []);

      debugPrint('fetchHistory decoded type: ${decoded.runtimeType}');

      List<dynamic> rawList = [];
      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map && decoded['data'] is List) {
        rawList = decoded['data'] as List<dynamic>;
      }

      if (rawList.isNotEmpty) {
        _buildStructure(rawList);
        _applyFilter();
        notifyListeners();
        return;
      }

      _loadFromFinishList();
    } catch (e) {
      debugPrint('fetchHistory error: $e');
      _loadFromFinishList();
    } finally {
      setBusy(false);
    }
  }

  void _buildStructure(List<dynamic> rawList) {
    final allItems = rawList
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    // Pisah berdasarkan field yang ada:
    // Process  → punya ProcessCode
    // BOM      → punya BOMCode, tidak punya ProcessCode
    // FOP hdr  → tidak punya BOMCode dan tidak punya ProcessCode
    final processItems = allItems
        .where((e) => e['ProcessCode'] != null)
        .toList();

    final bomItems = allItems
        .where((e) => e['BOMCode'] != null && e['ProcessCode'] == null)
        .toList();

    final fopHeaders = allItems
        .where((e) => e['BOMCode'] == null && e['ProcessCode'] == null)
        .toList();

    debugPrint(
      'Raw: ${fopHeaders.length} FOP, '
      '${bomItems.length} BOM, ${processItems.length} Process',
    );

    // Debug: cek sample FOPNumber dari masing-masing grup
    if (fopHeaders.isNotEmpty) {
      debugPrint(
        'FOP sample FOPNumbers: ${fopHeaders.take(3).map((e) => e['FOPNumber']).toList()}',
      );
    }
    if (bomItems.isNotEmpty) {
      debugPrint(
        'BOM sample FOPNumbers: ${bomItems.take(3).map((e) => e['FOPNumber']).toList()}',
      );
      debugPrint('BOM sample item: ${bomItems.first}');
    }
    if (processItems.isNotEmpty) {
      debugPrint(
        'Process sample FOPNumbers: ${processItems.take(3).map((e) => e['FOPNumber']).toList()}',
      );
    }

    // Kumpulkan semua FOPNumber unik dari BOM dan Process saja
    // (karena periode bisa berbeda dengan fopHeaders)
    final bomFopNumbers = bomItems
        .map((b) => b['FOPNumber']?.toString() ?? '')
        .where((n) => n.isNotEmpty)
        .toSet();

    final processFopNumbers = processItems
        .map((p) => p['FOPNumber']?.toString() ?? '')
        .where((n) => n.isNotEmpty)
        .toSet();

    // Semua FOPNumber dari ketiga grup
    final allFopNumbers = <String>{
      ...fopHeaders
          .map((h) => h['FOPNumber']?.toString() ?? '')
          .where((n) => n.isNotEmpty),
      ...bomFopNumbers,
      ...processFopNumbers,
    };

    // Map FOPNumber → header
    final headerMap = <String, Map<String, dynamic>>{};
    for (final h in fopHeaders) {
      final n = h['FOPNumber']?.toString() ?? '';
      if (n.isNotEmpty) headerMap[n] = h;
    }

    // Build FOP → BOM → Process untuk SEMUA FOPNumber unik
    final built = allFopNumbers.map((fopNum) {
      // Pakai header dari fopHeaders jika ada, fallback placeholder
      final header = headerMap[fopNum] ?? {'FOPNumber': fopNum};

      final boms = bomItems
          .where((b) => b['FOPNumber']?.toString() == fopNum)
          .map((bom) {
            final bomCode = bom['BOMCode']?.toString() ?? '';
            final processes = processItems
                .where(
                  (p) =>
                      p['FOPNumber']?.toString() == fopNum &&
                      p['BOMCode']?.toString() == bomCode,
                )
                .toList();
            return Map<String, dynamic>.from({
              ...bom,
              'ProcessList': processes,
            });
          })
          .toList();

      return Map<String, dynamic>.from({...header, 'BOMList': boms});
    }).toList();

    // Sort descending by FOPNumber (terbaru di atas)
    built.sort((a, b) {
      final na = a['FOPNumber']?.toString() ?? '';
      final nb = b['FOPNumber']?.toString() ?? '';
      return nb.compareTo(na);
    });

    _rawFopList = built;

    debugPrint(
      'Built: ${_rawFopList.length} FOP, '
      'sample BOMList: ${_rawFopList.isNotEmpty ? (_rawFopList[0]['BOMList'] as List).length : 0} BOM',
    );
  }

  void _loadFromFinishList() {
    _rawFopList = AppGlobals.finishList.isNotEmpty
        ? List.from(AppGlobals.finishList)
        : [];
    _applyFilter();
    notifyListeners();
  }

  @override
  Future<void> futureToRun() async {
    await fetchHistory();
  }
}
