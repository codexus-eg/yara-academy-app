import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../core/auth.dart';
import '../core/sheet.dart';
import 'tour.dart';

/// Session log (teacher: her own, supervisor: everyone's).
class LogPage extends StatefulWidget {
  const LogPage({super.key});
  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  Map<String, dynamic>? _r;
  String _f = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await context.read<Api>().get('/sessions/events', query: {'limit': 200, if (_f.isNotEmpty) 'held': _f});
      if (mounted) setState(() { _r = Map<String, dynamic>.from(r as Map); _loading = false; });
    } on ApiError catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        toast(context, e.message, error: true);
      }
    }
  }

  Future<void> _export() async {
    final api = context.read<Api>();
    try {
      final r = await api.dio.get<List<int>>('/sessions/events/export', queryParameters: {if (_f.isNotEmpty) 'held': _f}, options: Options(responseType: ResponseType.bytes, headers: {'Authorization': 'Bearer ${api.token}', 'x-device-id': api.deviceId}));
      if ((r.statusCode ?? 0) != 200 || r.data == null) throw ApiError('تعذّر التصدير');
      final path = await FilePicker.saveFile(dialogTitle: 'حفظ سجل الحصص', fileName: 'sessions-log.csv', bytes: Uint8List.fromList(r.data!));
      if (mounted && path != null) toast(context, 'تم حفظ الملف');
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } catch (_) {
      if (mounted) toast(context, 'تعذّر التصدير', error: true);
    }
  }

  Future<void> _delete(String id) async {
    if (!await askConfirm(context, 'حذف هذا السجل؟', ok: 'حذف')) return;
    try {
      await context.read<Api>().delete('/sessions/events/$id');
      await _load();
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sup = context.read<AuthState>().role == 'SUPERVISOR';
    final sum = (_r?['summary'] as Map?) ?? {};
    final items = ((_r?['items'] as List?) ?? []).cast<Map<String, dynamic>>();
    Widget stat(String v, String l) => Expanded(child: Column(children: [Text(v, style: Ya.display(size: 28, color: Ya.strong)), Text(l, style: const TextStyle(fontSize: 12.5, color: Ya.muted))]));
    return YaPage(
      title: 'سجل الحصص',
      actions: [IconButton(tooltip: 'تصدير CSV', icon: const Icon(Icons.download_rounded), onPressed: _export)],
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Ya.teal))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                SizedBox(
                  height: 38,
                  child: ListView(key: Tour.k('logfilter'), scrollDirection: Axis.horizontal, children: [
                    for (final e in const [('', 'الكل'), ('true', 'تمت'), ('false', 'لم تتم')])
                      Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: FilterPill(e.$2, selected: _f == e.$1, onTap: () {
                          setState(() => _f = e.$1);
                          _load();
                        }),
                      ),
                  ]),
                ),
                const SizedBox(height: 12),
                YaCard(
                  key: Tour.k('logsum'),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(children: [stat('${sum['total'] ?? 0}', 'الإجمالي'), stat('${sum['held'] ?? 0}', 'تمت'), stat('${sum['notHeld'] ?? 0}', 'لم تتم')]),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty) const EmptyState(title: 'مفيش سجلات', hint: 'هتظهر هنا كل حصة بعد تأكيدها.'),
                for (final e in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: YaCard(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(child: Text((e['course'] as Map?)?['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5))),
                          e['held'] == true ? Pill.ok('تمت') : Pill.bad('لم تتم'),
                        ]),
                        const SizedBox(height: 4),
                        Text('${(e['by'] as Map?)?['fullName'] ?? ''} · العدّاد ${e['num']} من ${e['total']}', style: const TextStyle(color: Ya.muted, fontSize: 13)),
                        Row(children: [
                          Expanded(child: Text(fdt(DateTime.parse('${e['createdAt']}').toLocal()), style: const TextStyle(color: Ya.muted, fontSize: 12.5))),
                          if (sup) TextButton(onPressed: () => _delete(e['id'] as String), child: const Text('حذف', style: TextStyle(color: Ya.danger))),
                        ]),
                      ]),
                    ),
                  ),
              ]),
            ),
    );
  }
}
