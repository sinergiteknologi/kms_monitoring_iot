import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:kms_monitoring_iot/core/app_globals.dart';
import 'package:kms_monitoring_iot/page/connect/connect_viewmodel.dart';
import 'package:stacked/stacked.dart';

class OngoingViewModel extends BaseViewModel {
  List<Map<String, dynamic>> ongoingList = [];

  String? _baseUrl;
  StreamSubscription<void>? _refreshSubscription;
  StreamSubscription<bool>? _timerControlSubscription;
  Timer? _autoRefreshTimer;

  static const Duration _interval = Duration(seconds: 5);
  static const Duration _requestTimeout = Duration(seconds: 10);

  OngoingViewModel() {
    _refreshSubscription = AppGlobals.ongoingRefreshStream.listen((_) {
      getOngoingList();
    });

    _timerControlSubscription = AppGlobals.ongoingTimerStream.listen((start) {
      if (start) {
        _startTimer();
      } else {
        _stopTimer();
      }
    });
  }

  void _startTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_interval, (_) => getOngoingList());
    debugPrint(
      'OngoingViewModel: auto-refresh started ${_interval.inSeconds}s',
    );
  }

  void _stopTimer() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
    debugPrint('OngoingViewModel: auto-refresh stopped');
  }

  /// Support input yang tersimpan dalam bentuk:
  /// - 192.168.1.10
  /// - 192.168.1.10:1346
  /// - http://192.168.1.10:1346
  /// - http://192.168.1.10:1346/ApiKMS
  Future<String?> _getBaseUrl() async {
    if (_baseUrl != null) return _baseUrl;

    final savedIp = await ConnectViewModel.getSavedIp();
    final raw = savedIp?.trim() ?? AppGlobals.serverIp.trim();
    if (raw.isEmpty) {
      debugPrint('OngoingViewModel: server IP/baseUrl belum tersimpan');
      return null;
    }

    var value = raw;
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'http://$value';
    }

    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) {
      debugPrint('OngoingViewModel: baseUrl tidak valid: $raw');
      return null;
    }

    final port = uri.hasPort ? uri.port : 1346;
    _baseUrl = '${uri.scheme}://${uri.host}:$port';
    return _baseUrl;
  }

  Uri _apiUri(String path, {Map<String, dynamic>? queryParameters}) {
    final base = _baseUrl!;
    final normalizedPath = path.startsWith('/') ? path : '/$path';

    final Map<String, String>? query = queryParameters?.map(
      (key, value) => MapEntry(key, value?.toString() ?? ''),
    );

    query?.removeWhere((key, value) => value.isEmpty || value == 'null');

    return Uri.parse(
      '$base$normalizedPath',
    ).replace(queryParameters: query == null || query.isEmpty ? null : query);
  }

  int getCountValue(int index) {
    if (index < 0 || index >= ongoingList.length) return 0;
    return _parseToInt(ongoingList[index]['CountValue']);
  }

  int _parseToInt(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == '-') return 0;
    return int.tryParse(text) ?? double.tryParse(text)?.round() ?? 0;
  }

  num? _parseToNum(dynamic value) {
    final text = value?.toString().trim().replaceAll(',', '.') ?? '';
    if (text.isEmpty || text == '-') return null;
    return num.tryParse(text);
  }

  String _nowTimestamp() {
    return DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(DateTime.now());
  }

  List<Map<String, dynamic>> _extractList(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is List) {
        return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      if (data is Map) {
        return [Map<String, dynamic>.from(data)];
      }
    }

    if (decoded is List) {
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    return [];
  }

  bool _isSuccessResponse(int statusCode, dynamic decoded) {
    if (statusCode < 200 || statusCode >= 300) return false;
    if (decoded is Map<String, dynamic> && decoded.containsKey('success')) {
      return decoded['success'] == true;
    }
    return true;
  }

  /// Ambil list On Process dari ApiKMS.
  /// Endpoint utama mengikuti script ApiKMS: /ApiKMS/api/getCounting
  Future<void> getOngoingList() async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) {
      ongoingList = [];
      AppGlobals.setOngoingCount(0);
      notifyListeners();
      return;
    }

    setBusy(true);
    try {
      final uri = _apiUri(
        '/ApiKMS/api/getCounting',
        queryParameters: {'AccountID': AppGlobals.accountID},
      );

      debugPrint('getOngoingList GET: $uri');

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(_requestTimeout);

      debugPrint('getOngoingList status: ${response.statusCode}');
      debugPrint('getOngoingList response body: ${response.body}');

      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);

      if (_isSuccessResponse(response.statusCode, decoded)) {
        ongoingList = _extractList(decoded);
        AppGlobals.setOngoingCount(ongoingList.length);
      } else {
        ongoingList = [];
        AppGlobals.setOngoingCount(0);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('getOngoingList error: $e');
    } finally {
      setBusy(false);
    }
  }

  /// Submit finish counting ke ApiKMS.
  /// Body disesuaikan dengan logic ApiKMS script kedua dan tetap cocok dengan UI script pertama.
  Future<bool> saveTotalCount({
    required int index,
    required int adjustmentValue,
    required int totalCount,
  }) async {
    if (index < 0 || index >= ongoingList.length) {
      debugPrint('saveTotalCount error: index tidak valid ($index)');
      return false;
    }

    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) return false;

    final item = ongoingList[index];
    final countValue = getCountValue(index);

    final body = <String, dynamic>{
      'AccountID': item['AccountID'] ?? AppGlobals.accountID,
      'ObjectID': item['ObjectID'] ?? AppGlobals.objectID,
      'SensorID': item['SensorID'] ?? item['SensorCode'] ?? '',
      'ProcesID':
          item['ProcesID'] ?? item['ProcessID'] ?? item['ProcessNumber'] ?? '',
      'RefNumber':
          item['RefNumber'] ?? item['FOPNumber'] ?? item['FOPNo'] ?? '',
      'StartDate': item['StartDate'],
      'EndDate': _nowTimestamp(),
      'TotalCount': totalCount,
      'CountValue': countValue,
      'AdjustValue': adjustmentValue,
      'StartCount': _parseToInt(item['StartCount']),
      'CurrentCount': _parseToInt(item['CurrentCount']),
    };

    // Jika data awal membawa CountingFormula dari Task List, ikut dikirim ke ApiKMS.
    final countingFormula =
        item['CountingFormula'] ?? item['CountingFormulaValue'];
    final countingFormulaValue = _parseToNum(countingFormula);
    if (countingFormulaValue != null) {
      body['CountingFormula'] = countingFormulaValue;
    }

    setBusy(true);
    try {
      final uri = _apiUri('/ApiKMS/api/postCounting');
      debugPrint('saveTotalCount POST: $uri');
      debugPrint('saveTotalCount body: ${jsonEncode(body)}');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);

      debugPrint('saveTotalCount status: ${response.statusCode}');
      debugPrint('saveTotalCount response: ${response.body}');

      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      final success = _isSuccessResponse(response.statusCode, decoded);

      if (success) {
        await getOngoingList();
        AppGlobals.triggerFinishRefresh();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('saveTotalCount error: $e');
      return false;
    } finally {
      setBusy(false);
    }
  }

  @override
  void dispose() {
    _stopTimer();
    _refreshSubscription?.cancel();
    _timerControlSubscription?.cancel();
    super.dispose();
  }
}
