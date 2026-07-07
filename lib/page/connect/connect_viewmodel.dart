import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kms_monitoring_iot/core/app_globals.dart';
import 'package:kms_monitoring_iot/core/web_network.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stacked/stacked.dart';

class ConnectViewModel extends BaseViewModel {
  static const String _serverIpKey = 'SERVER_IP';
  static const Duration _connectTimeout = Duration(seconds: 6);

  final TextEditingController ipController = TextEditingController();

  String deviceIp = '';

  Future<void> init() async {
    await loadSavedIp();
    await loadDeviceIp();
  }

  Future<void> loadSavedIp() async {
    final savedIp = await getSavedIp();
    ipController.text = savedIp ?? '';
    notifyListeners();
  }

  Future<void> loadDeviceIp() async {
    // Placeholder. Jika nanti ingin menampilkan IP HP,
    // bisa gunakan package network_info_plus.
    deviceIp = '';
    notifyListeners();
  }

  static Future<String?> getSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_serverIpKey);
  }

  static Future<void> clearSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_serverIpKey);

    AppGlobals.serverIp = '';
    AppGlobals.isConnected = false;
  }

  /// Normalisasi input menjadi base URL tanpa path.
  ///
  /// Support:
  /// - 192.168.1.10
  /// - 192.168.1.10:1346
  /// - http://192.168.1.10:1346
  /// - http://192.168.1.10:1346/ApiKMS
  ///
  static String normalizeBaseUrl(String input) {
    var value = input.trim();

    if (value.isEmpty) return '';

    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'http://$value';
    }

    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return '';

    final port = uri.hasPort ? uri.port : 1346;

    // return '${uri.scheme}://${uri.host}';
    return '${uri.scheme}://${uri.host}:$port';
  }

  static Object? lastConnectionError;

  static Future<bool> verifyConnection(String input) async {
    final baseUrl = normalizeBaseUrl(input);
    if (baseUrl.isEmpty) return false;

    lastConnectionError = null;
    final endpoints = <String>['/ApiKMS/api/status'];

    for (final endpoint in endpoints) {
      try {
        final uri = Uri.parse('$baseUrl$endpoint');
        final response = await http
            .get(uri, headers: {'Accept': 'application/json'})
            .timeout(_connectTimeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          AppGlobals.serverIp = baseUrl;
          AppGlobals.isConnected = true;
          return true;
        }
      } catch (error) {
        lastConnectionError = error;
      }
    }

    AppGlobals.isConnected = false;
    return false;
  }

  Future<void> connect({required String ipConnect}) async {
    final input = ipConnect.trim();

    if (input.isEmpty) {
      _showMessage('IP Address server harus diisi');
      return;
    }

    setBusy(true);

    try {
      final baseUrl = normalizeBaseUrl(input);

      if (baseUrl.isEmpty) {
        AppGlobals.isConnected = false;
        _showMessage('Format IP Address server tidak valid');
        return;
      }

      final isConnected = await verifyConnection(baseUrl);

      if (!isConnected) {
        AppGlobals.isConnected = false;
        _showMessage(
          WebNetwork.connectionFailureMessage(
            error: lastConnectionError,
          ),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_serverIpKey, baseUrl);

      AppGlobals.serverIp = baseUrl;
      AppGlobals.isConnected = true;

      _showMessage('Berhasil terhubung ke server');

      await Future.delayed(const Duration(milliseconds: 250));

      AppGlobals.globalNavigatorKey.currentState?.pushReplacementNamed('/home');
    } catch (e) {
      AppGlobals.isConnected = false;
      debugPrint('ConnectViewModel.connect error: $e');
      _showMessage('Gagal konek ke server');
    } finally {
      setBusy(false);
    }
  }

  void _showMessage(String message) {
    final context = AppGlobals.globalNavigatorKey.currentContext;
    if (context == null) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    ipController.dispose();
    super.dispose();
  }
}
