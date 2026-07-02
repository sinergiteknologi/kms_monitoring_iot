import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kms_monitoring_iot/core/app_globals.dart';
import 'package:kms_monitoring_iot/page/connect/connect_viewmodel.dart';
import 'package:stacked/stacked.dart';

class FinishViewModel extends BaseViewModel {
  List<Map<String, dynamic>> finishList = [];
  String? errorMessage;
  String? _baseUrl;
  StreamSubscription<void>? _refreshSubscription;

  final Map<int, TextEditingController> _controllers = {};

  FinishViewModel() {
    _refreshSubscription = AppGlobals.finishRefreshStream.listen((_) {
      getFinishList();
    });
  }

  TextEditingController getController(int index) {
    if (index < 0 || index >= finishList.length) {
      return TextEditingController(text: '0');
    }

    if (!_controllers.containsKey(index)) {
      _controllers[index] = TextEditingController(
        text: _asInt(finishList[index]['TotalCount']).toString(),
      );
    }

    return _controllers[index]!;
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

  Future<void> getFinishList() async {
    final baseUrl = await _getBaseUrl();

    if (baseUrl == null) {
      errorMessage = 'IP server belum tersimpan';
      finishList = [];
      AppGlobals.setFinishCount(0);
      notifyListeners();
      return;
    }

    setBusy(true);
    errorMessage = null;

    try {
      final uri = Uri.parse(
        '$baseUrl/ApiKMS/api/getCountingFinish',
      ).replace(queryParameters: {'AccountID': AppGlobals.accountID});

      debugPrint('getFinishList GET: $uri');

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 15));

      debugPrint('getFinishList status: ${response.statusCode}');
      debugPrint('getFinishList body: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        finishList = [];
        AppGlobals.setFinishCount(0);
        errorMessage = 'Gagal memuat data finish (${response.statusCode})';
        notifyListeners();
        return;
      }

      final decoded = jsonDecode(response.body);
      final data = _extractData(decoded);

      finishList = data;
      AppGlobals.setFinishCount(finishList.length);

      _resetControllers();
      notifyListeners();
    } on TimeoutException {
      errorMessage = 'Koneksi timeout saat memuat data finish';
      debugPrint('getFinishList timeout');
      notifyListeners();
    } catch (e) {
      errorMessage = 'Gagal memuat data finish';
      debugPrint('getFinishList error: $e');
      notifyListeners();
    } finally {
      setBusy(false);
    }
  }

  Future<bool> updateTotalCount({
    required int index,
    required BuildContext ctx,
  }) async {
    if (index < 0 || index >= finishList.length) {
      _showMessage(ctx, 'Data finish tidak valid');
      return false;
    }

    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) {
      _showMessage(ctx, 'IP server belum tersimpan');
      return false;
    }

    final item = finishList[index];
    final controller = getController(index);
    final newTotalCount =
        int.tryParse(controller.text.trim()) ??
        _asInt(item['TotalCount'] ?? item['TotalCounting']);

    final body = _buildPostCountingPayload(
      item: item,
      totalCount: newTotalCount,
    );

    setBusy(true);

    try {
      debugPrint('postCounting URL: $baseUrl/ApiKMS/api/postCounting');
      debugPrint('postCounting body: ${jsonEncode(body)}');

      final response = await http
          .post(
            Uri.parse('$baseUrl/ApiKMS/api/postCounting'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('postCounting status: ${response.statusCode}');
      debugPrint('postCounting response: ${response.body}');

      final decoded = response.body.trim().isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);

      final isSuccess =
          response.statusCode >= 200 &&
          response.statusCode < 300 &&
          _isSuccessResponse(decoded);

      if (!isSuccess) {
        final message = _extractMessage(decoded) ?? 'Gagal update total count';
        _showMessage(ctx, message);
        return false;
      }

      finishList[index] = {
        ...finishList[index],
        'TotalCount': newTotalCount,
        'TotalCounting': newTotalCount,
        'CountValue': body['CountValue'],
        'AdjustValue': body['AdjustValue'],
        'CountingFormula': body['CountingFormula'],
      };

      notifyListeners();
      _showMessage(ctx, 'Total count berhasil diperbarui');
      return true;
    } on TimeoutException {
      _showMessage(ctx, 'Koneksi timeout saat update total count');
      debugPrint('updateTotalCount timeout');
      return false;
    } catch (e) {
      _showMessage(ctx, 'Gagal update total count');
      debugPrint('updateTotalCount error: $e');
      return false;
    } finally {
      setBusy(false);
    }
  }

  Map<String, dynamic> _buildPostCountingPayload({
    required Map<String, dynamic> item,
    required int totalCount,
  }) {
    final countValue = _asInt(item['CountValue'] ?? item['Counting']);
    final adjustValue = _asInt(item['AdjustValue']);
    final countingFormula = _asNum(
      item['CountingFormula'] ?? item['Formula'] ?? item['FormulaCount'],
      defaultValue: 1,
    );

    return {
      'AccountID': item['AccountID'] ?? AppGlobals.accountID,
      'ObjectID': item['ObjectID'] ?? AppGlobals.objectID,
      'SensorID': item['SensorID'] ?? item['SensorId'] ?? item['SensorName'],
      'ProcesID':
          item['ProcesID'] ?? item['ProcessID'] ?? item['ProcessNumber'],
      'RefNumber': item['RefNumber'] ?? item['FOPNumber'] ?? item['FopNumber'],
      'StartDate': item['StartDate'],
      'EndDate': item['EndDate'],
      'TotalCount': totalCount,
      'CountValue': countValue,
      'AdjustValue': adjustValue,
      'CountingFormula': countingFormula,
      'StartCount': _asInt(item['StartCount']),
      'CurrentCount': _asInt(item['CurrentCount'] ?? countValue),
    };
  }

  List<Map<String, dynamic>> _extractData(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'] ?? decoded['Data'] ?? decoded['result'];

      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      if (data is Map) {
        return [Map<String, dynamic>.from(data)];
      }
    }

    return [];
  }

  bool _isSuccessResponse(dynamic decoded) {
    if (decoded is! Map) return true;

    final value =
        decoded['success'] ??
        decoded['Success'] ??
        decoded['status'] ??
        decoded['Status'];

    if (value == null) return true;

    if (value is bool) return value;

    final text = value.toString().toLowerCase();
    return text == 'true' || text == 'success' || text == 'ok' || text == '1';
  }

  String? _extractMessage(dynamic decoded) {
    if (decoded is! Map) return null;

    return decoded['message']?.toString() ??
        decoded['Message']?.toString() ??
        decoded['error']?.toString() ??
        decoded['Error']?.toString();
  }

  int _asInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.round();

    final text = value.toString().trim();
    if (text.isEmpty) return defaultValue;

    return int.tryParse(text) ?? double.tryParse(text)?.round() ?? defaultValue;
  }

  num _asNum(dynamic value, {num defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is num) return value;

    final text = value.toString().trim().replaceAll(',', '.');
    if (text.isEmpty) return defaultValue;

    return num.tryParse(text) ?? defaultValue;
  }

  void _resetControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  void _showMessage(BuildContext ctx, String message) {
    if (!ctx.mounted) return;

    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    _resetControllers();
    super.dispose();
  }
}
