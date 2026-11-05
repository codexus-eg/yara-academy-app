import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'api.dart';

/// Push notifications (FCM).
/// Safe without `android/app/google-services.json`: initialisation fails quietly and everything stays off.
class Push {
  // Firebase iOS app "Yara iOS" (com.yara.yaraAcademy). These are client identifiers, not secrets.
  static const _iosOptions = FirebaseOptions(
    apiKey: 'AIzaSyBZ-z-ZrFk0fzvaYqW1Jn-4WAWY_1tZw6c',
    appId: '1:17974910911:ios:6bbcb3e29127a664380b0a',
    messagingSenderId: '17974910911',
    projectId: 'device-streaming-2ca492cd',
    iosBundleId: 'com.yara.yaraAcademy',
  );

  static bool _ready = false;
  static bool _tried = false;
  static String? _token;
  static StreamSubscription<String>? _refreshSub;

  static Future<bool> _init() async {
    if (_ready) return true;
    if (_tried) return false;
    _tried = true;
    try {
      await Firebase.initializeApp(options: Platform.isIOS ? _iosOptions : null);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  /// Call after the user is signed in.
  static Future<void> register(Api api) async {
    try {
      if (!await _init()) return;
      final fm = FirebaseMessaging.instance;
      await fm.requestPermission();
      final t = await fm.getToken();
      if (t == null) return;
      _token = t;
      await _send(api, t);
      _refreshSub ??= fm.onTokenRefresh.listen((nt) {
        _token = nt;
        _send(api, nt);
      });
    } catch (_) {
      // never let push break login
    }
  }

  static Future<void> _send(Api api, String t) async {
    try {
      if (api.token == null) return;
      await api.post('/push/token', body: {'token': t, 'platform': Platform.isIOS ? 'ios' : 'android'});
    } catch (_) {}
  }

  /// Call before signing out so the next person on this phone doesn't get this user's notifications.
  static Future<void> unregister(Api api) async {
    final t = _token;
    if (t == null || api.token == null) return;
    try {
      await api.request('DELETE', '/push/token', body: {'token': t});
    } catch (_) {}
  }
}
