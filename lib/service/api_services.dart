import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as encrypt;

class ApiServices {
  static const String baseUrl =
      'https://production3.sinergiteknologi.co.id/KMSIOT/api/mobile';

  String encryptData(String plainText) {
    final key = encrypt.Key.fromUtf8('#Sinergi132465#Sinergi!132465!16');
    final iv = encrypt.IV.fromUtf8('ivSinergi#132465');

    final encrypter = encrypt.Encrypter(
      encrypt.AES(key, mode: encrypt.AESMode.cbc),
    );
    final encrypted = encrypter.encrypt(plainText, iv: iv);

    return encrypted.base64;
  }

  Future<Map<String, dynamic>> post(String url, dynamic body) async {
    final headers = {'Content-Type': 'application/json; charset=UTF-8'};
    print("base url  : $baseUrl$url");
    print("bpdy  : ${jsonEncode(body)}");
    final response = await http.post(
      Uri.parse('$baseUrl$url'),
      body: jsonEncode(body),
      headers: headers,
    );
    print("response  : ${response.statusCode}");
    print("response  : ${response.body}");

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// GET request — return dynamic (List atau Map)
  Future<dynamic> getRaw(
    String url, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse('$baseUrl$url').replace(
      queryParameters: queryParameters,
    );
    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    );
    debugPrint('getRaw $url status: ${response.statusCode}');
    return jsonDecode(response.body);
  }

  /// Sama seperti [post] tapi return dynamic — untuk endpoint yang return List
  Future<dynamic> postRaw(String url, dynamic body) async {
    if (body is List && body.isEmpty) {
      final response = await http.get(Uri.parse('$baseUrl$url'));
      debugPrint('postRaw $url status: ${response.statusCode}');
      return jsonDecode(response.body);
    } else {
      final headers = {'Content-Type': 'application/json; charset=UTF-8'};
      final response = await http.post(
        Uri.parse('$baseUrl$url'),
        body: jsonEncode(body),
        headers: headers,
      );
      debugPrint('postRaw $url status: ${response.statusCode}');
      return jsonDecode(response.body);
    }
  }
}
