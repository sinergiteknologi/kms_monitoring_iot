import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:kms_monitoring_iot/core/app_globals.dart';
import 'package:kms_monitoring_iot/page/connect/connect_viewmodel.dart';

class CountingService {
  CountingService._();

  static String? _baseUrl;

  static Future<String?> _getBaseUrl() async {
    if (_baseUrl != null) return _baseUrl;
    final ip = await ConnectViewModel.getSavedIp();
    if (ip == null) return null;
    _baseUrl = 'http://$ip:1346';
    return _baseUrl;
  }

  /// POST /ApiKMS/api/postCounting
  /// Dipakai untuk insert baru maupun update (EndDate + TotalCount)
  static Future<bool> postCounting(Map<String, dynamic> body) async {
    final baseUrl = await _getBaseUrl();
    if (baseUrl == null) {
      return false;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/ApiKMS/api/postCounting'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      final result = jsonDecode(response.body) as Map<String, dynamic>;

      if ((response.statusCode == 201 || response.statusCode == 200) &&
          result['success'] == true) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Update TotalCount item di index tertentu lalu POST ke server
  static Future<bool> saveTotalCount({
    required int index,
    required int totalCount,
  }) async {
    if (index < 0 || index >= AppGlobals.taskList.length) return false;

    final item = AppGlobals.taskList[index];

    final body = {
      'AccountID': item['AccountID'] ?? AppGlobals.accountID,
      'ObjectID': item['ObjectID'] ?? AppGlobals.objectID,
      'SensorID': item['SensorID'],
      'ProcesID': item['ProcesID'],
      'RefNumber': item['RefNumber'],
      'StartDate': item['StartDate'],
      'EndDate': DateFormat(
        'yyyy-MM-dd HH:mm:ss.SSSSSS',
      ).format(DateTime.now()),
      'TotalCount': totalCount,
      'CountValue': item['CountValue'] ?? 0,
    };

    final success = await postCounting(body);

    if (success) {
      // Pindahkan item ke finishList
      final finishedItem = {
        ...AppGlobals.taskList[index],
        'TotalCount': totalCount,
      };
      await AppGlobals.addToFinishList(finishedItem);
      // Hapus dari taskList dan SharedPreferences
      await AppGlobals.removeTaskAt(index);
    }

    return success;
  }
}
