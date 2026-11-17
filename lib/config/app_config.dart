import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConfig {
  static String _overrideBaseUrl = '';

  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    if (kIsWeb) return 'http://localhost:3000/api';
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://127.0.0.1:3000/api';
    }
    return 'http://10.0.2.2:3000/api';
  }

  static void setBaseUrl(String url) {
    _overrideBaseUrl = url;
  }
}
