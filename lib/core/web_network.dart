import 'package:flutter/foundation.dart';

class WebNetwork {
  static bool isLikelyCorsOrFetchError(Object error) {
    if (!kIsWeb) return false;

    final message = error.toString().toLowerCase();
    return message.contains('failed to fetch') ||
        message.contains('xmlhttprequest error') ||
        message.contains('networkerror') ||
        message.contains('cors');
  }

  static String connectionFailureMessage({Object? error}) {
    if (kIsWeb && error != null && isLikelyCorsOrFetchError(error)) {
      return 'Gagal konek di web. Server ApiKMS perlu mengaktifkan CORS '
          '(Access-Control-Allow-Origin) untuk domain web ini.';
    }

    if (kIsWeb) {
      return 'Gagal konek ke server ApiKMS dari browser. '
          'Pastikan server aktif dan CORS sudah diizinkan.';
    }

    return 'Gagal konek ke server ApiKMS';
  }
}
