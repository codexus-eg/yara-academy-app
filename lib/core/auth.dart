import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'config.dart';
import 'push.dart';

enum AuthStatus { booting, offline, signedOut, signedIn }

/// Keeps the user signed in as long as possible:
///  - the token lives in secure storage and is renewed on every open (sliding expiry)
///  - network errors / a restarting server never sign the user out (we show "reconnecting" and retry)
///  - only a token the server really rejects signs out
class AuthState extends ChangeNotifier with WidgetsBindingObserver {
  AuthState(this.api) {
    WidgetsBinding.instance.addObserver(this);
    api.onUnauthorized = () => signOut();
  }

  final Api api;
  final _secure = const FlutterSecureStorage();

  AuthStatus status = AuthStatus.booting;
  Map<String, dynamic>? user;
  Timer? _timer;
  DateTime _lastRefresh = DateTime.now();

  String get role => (user?['role'] as String?) ?? '';
  String get name => (user?['fullName'] as String?) ?? '';
  String get id => (user?['id'] as String?) ?? '';
  String? get studentCode => user?['studentCode'] as String?;
  bool get isStudent => role == 'STUDENT';
  bool get isTeacher => role == 'TEACHER';
  bool get isSupervisor => role == 'SUPERVISOR';

  static String _randomId() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> boot() async {
    final prefs = await SharedPreferences.getInstance();
    var dev = prefs.getString('ya_dev');
    if (dev == null) {
      dev = _randomId();
      await prefs.setString('ya_dev', dev);
    }
    api.deviceId = dev;

    final saved = await _readToken();
    if (saved == null) {
      status = AuthStatus.signedOut;
      notifyListeners();
      return;
    }
    api.token = saved;
    while (true) {
      try {
        _accept(await api.get('/auth/me'));
        return;
      } on ApiError catch (e) {
        if (e.status == 401 || e.status == 403) {
          await _clear();
          status = AuthStatus.signedOut;
          notifyListeners();
          return;
        }
        // offline / server restarting / rate limited: keep the session and retry
        status = AuthStatus.offline;
        notifyListeners();
        await Future<void>.delayed(Duration(seconds: e.status == 429 ? 15 : 3));
      }
    }
  }

  Future<String?> _readToken() async {
    try {
      return await _secure.read(key: 'ya_token');
    } catch (_) {
      return (await SharedPreferences.getInstance()).getString('ya_token_fb');
    }
  }

  Future<void> _writeToken(String? t) async {
    try {
      if (t == null) {
        await _secure.delete(key: 'ya_token');
      } else {
        await _secure.write(key: 'ya_token', value: t);
      }
    } catch (_) {
      final p = await SharedPreferences.getInstance();
      t == null ? await p.remove('ya_token_fb') : await p.setString('ya_token_fb', t);
    }
  }

  void _accept(dynamic r) {
    final map = r as Map<String, dynamic>;
    user = map['user'] as Map<String, dynamic>;
    final t = map['token'] as String?;
    if (t != null) {
      api.token = t;
      _writeToken(t);
    }
    status = AuthStatus.signedIn;
    _lastRefresh = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(Config.sessionRefreshEvery, (_) => refresh());
    Push.register(api);
    notifyListeners();
  }

  Future<void> login(String code) async {
    final r = await api.post('/auth/login', body: {'code': code.trim()});
    _accept(r);
  }

  /// Creates a student account; the server returns the student's login code in `user.studentCode`.
  Future<void> register(String fullName) async {
    final r = await api.post('/auth/student/register', body: {'fullName': fullName.trim()});
    _accept(r);
  }

  Future<void> refresh() async {
    if (status != AuthStatus.signedIn) return;
    try {
      final r = await api.get('/auth/me') as Map<String, dynamic>;
      user = r['user'] as Map<String, dynamic>;
      final t = r['token'] as String?;
      if (t != null) {
        api.token = t;
        await _writeToken(t);
      }
      _lastRefresh = DateTime.now();
    } on ApiError {
      // offline: try again later
    }
  }

  Future<void> signOut() async {
    _timer?.cancel();
    await Push.unregister(api);
    api.token = null;
    user = null;
    await _clear();
    status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<void> _clear() => _writeToken(null);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && DateTime.now().difference(_lastRefresh) > const Duration(hours: 1)) {
      refresh();
    }
  }
}
