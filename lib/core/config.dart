import 'package:flutter/foundation.dart';

/// Where the Yara backend lives.
/// Override with: flutter run --dart-define=API_BASE=https://your-domain
class Config {
  static const _define = String.fromEnvironment('API_BASE');

  static String get baseUrl {
    if (_define.isNotEmpty) return _define;
    if (kIsWeb) return 'http://localhost:4000';
    return 'http://10.0.2.2:4000'; // Android emulator -> the PC running the server
  }

  static const sessionRefreshEvery = Duration(hours: 6);
}
