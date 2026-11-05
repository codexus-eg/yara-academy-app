import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api.dart';
import 'config.dart';

/// Account-wide live events (same as the website's connectSocket): toasts + list refresh.
/// Pages add a listener and reload when notified.
class Live extends ChangeNotifier {
  Live(this._api);
  final Api _api;
  io.Socket? _s;

  /// Set by the shell: shows a toast (message, celebrate?).
  void Function(String msg, {bool celebrate})? onMessage;

  void connect() {
    if (_s != null || _api.token == null) return;
    final s = io.io(Config.baseUrl, io.OptionBuilder().setTransports(['websocket']).setAuth({'token': _api.token}).disableAutoConnect().build());
    s.on('subscription:updated', (d) {
      final st = d is Map ? d['status'] : null;
      onMessage?.call(
        st == 'ACTIVE' ? 'تمت الموافقة على اشتراكك 🎉' : st == 'REJECTED' ? 'تم رفض طلب الاشتراك' : 'تحديث في اشتراكك',
        celebrate: st == 'ACTIVE',
      );
      notifyListeners();
    });
    s.on('subscription:completed', (_) {
      onMessage?.call('🏆 مبروك! اكتملت حصصك في أحد الكورسات', celebrate: true);
      notifyListeners();
    });
    s.on('subscription:new', (d) {
      onMessage?.call('طلب اشتراك جديد من ${d is Map ? (d['studentName'] ?? '') : ''}');
      notifyListeners();
    });
    s.connect();
    _s = s;
  }

  @override
  void dispose() {
    _s?.dispose();
    _s = null;
    super.dispose();
  }
}
