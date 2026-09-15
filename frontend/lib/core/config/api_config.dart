import 'dart:io';

import 'package:flutter/foundation.dart';

class ApiConfig {
  // Base URL for all API requests — adjust per platform when running locally
  static String get base_url {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000/api';
    }

    if (Platform.isAndroid) {
      // Android emulator maps host machine localhost to 10.0.2.2
      return 'http://192.168.1.7:8000/api';
    }

    // iOS simulator, Windows, macOS, Linux
    return 'http://127.0.0.1:8000/api';
  }

  static const int timeout_seconds = 30;

  static const String client_key = 'santayo_09012026_4321423664556';
}
