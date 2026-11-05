import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// A session lasts 50 minutes; free Zoom cuts a meeting at 40.
const sessionMin = 50, zoomMin = 40, zoomWarn = 5;

bool sessionDue(Course c) {
  final since = DateTime.tryParse('${c.json['pendingSince'] ?? ''}');
  return c.pendingConfirmation && since != null && DateTime.now().isAfter(since.add(const Duration(minutes: sessionMin)));
}

/// "هل تمت الحصة؟" box shown on a course that waits for confirmation (teacher + supervisor).
class ConfirmBox extends StatelessWidget {
  const ConfirmBox({super.key, required this.pendingSince, required this.onConfirm, required this.onAttendance});
  final DateTime? pendingSince;
  final void Function(bool held) onConfirm;
  final VoidCallback onAttendance;

  @override
  Widget build(BuildContext context) {
    final since = pendingSince;
    final due = since != null && DateTime.now().isAfter(since.add(const Duration(minutes: sessionMin)));
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: due ? Ya.warnBg : Ya.soft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: due ? Ya.gold : Colors.transparent, width: 1.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(due ? '⏰ انتهى وقت الحصة، هل تمت؟' : 'هل تمت الحصة؟', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: GradButton(label: 'تمت', gradient: Ya.waGradient, height: 42, onPressed: () => onConfirm(true))),
          const SizedBox(width: 8),
          Expanded(child: SoftButton(label: 'لم تتم', height: 42, onPressed: () => onConfirm(false))),
        ]),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onAttendance, child: const Text('👥 الحضور')),
      ]),
    );
  }
}

/// Confirm the session (with a dialog) and report back.
Future<bool> confirmSession(BuildContext context, String courseId, bool held, {String? studentId}) async {
  final sure = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(held ? 'تأكيد: الحصة تمت؟' : 'تأكيد: الحصة لم تتم؟'),
      content: Text(held ? 'هتتحسب الحصة للطالب (إلا لو مسجّل غائب بعذر).' : 'مش هتتحسب أي حصة.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('رجوع')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('تأكيد')),
      ],
    ),
  );
  if (sure != true || !context.mounted) return false;
  try {
    await context.read<Api>().post('/courses/$courseId/sessions/confirm', body: {'held': held, if (studentId != null) 'studentId': studentId});
    if (context.mounted) toast(context, held ? '✅ تم تسجيل الحصة، أحسنت!' : 'تم تسجيل أن الحصة لم تتم');
    return true;
  } on ApiError catch (e) {
    if (context.mounted) toast(context, e.message, error: true);
    return false;
  }
}

/// Attendance bottom sheet (only while a session is open).
Future<void> showAttendanceSheet(BuildContext context, String courseId, {String? studentId}) {
  final api = context.read<Api>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (_) => Provider<Api>.value(value: api, child: _AttendanceSheet(courseId, studentId)),
  );
}

class _AttendanceSheet extends StatefulWidget {
  const _AttendanceSheet(this.courseId, this.studentId);
  final String courseId;
  final String? studentId;
  @override
  State<_AttendanceSheet> createState() => _AttendanceSheetState();
}

class _AttendanceSheetState extends State<_AttendanceSheet> {
  Map<String, dynamic>? _r;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await context.read<Api>().get('/courses/${widget.courseId}/attendance', query: {if (widget.studentId != null) 'studentId': widget.studentId});
      if (mounted) setState(() => _r = Map<String, dynamic>.from(r as Map));
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _mark(String sid, String? cur, String st) async {
    setState(() => _busy = true);
    try {
      await context.read<Api>().put('/courses/${widget.courseId}/attendance/$sid', body: {'status': cur == st ? null : st});
      await _load();
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _r;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * .88),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 44, height: 5, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Ya.line, borderRadius: BorderRadius.circular(3)))),
            Text('👥 الحضور', style: Ya.display(size: 25)),
            const SizedBox(height: 8),
            if (r == null)
              const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(color: Ya.teal)))
            else if (r['open'] != true)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Ya.warnBg, borderRadius: BorderRadius.circular(14)),
                child: const Text('تسجيل الحضور يفتح أثناء الحصة، بعد إرسال رابط Zoom وقبل تأكيد "تمت".', style: TextStyle(color: Ya.warn, height: 1.6)),
              )
            else ..._body(r),
            const SizedBox(height: 14),
            GradButton(label: 'تم', onPressed: () => Navigator.pop(context)),
          ]),
        ),
      ),
    );
  }

  List<Widget> _body(Map<String, dynamic> r) {
    final s = (r['summary'] as Map?) ?? {};
    final items = ((r['items'] as List?) ?? []).cast<Map<String, dynamic>>();
    final closed = r['closed'] == true;
    Widget stat(String v, String l) => Expanded(child: Column(children: [Text(v, style: Ya.display(size: 24, color: Ya.strong)), Text(l, style: const TextStyle(fontSize: 12, color: Ya.muted))]));
    return [
      Text(closed ? 'حصة منتهية، تعديل المشرف فقط، ولا يغيّر عدّاد الحصص.' : 'متاح أثناء الحصة فقط، ويقفل بعد تأكيد "تمت". اللي يُسجَّل "غائب بعذر" ما تنخصم منه الحصة.', style: const TextStyle(color: Ya.muted, fontSize: 13, height: 1.6)),
      const SizedBox(height: 10),
      YaCard(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [stat('${s['present'] ?? 0}', 'حاضر'), stat('${s['absent'] ?? 0}', 'غائب'), stat('${s['excused'] ?? 0}', 'بعذر'), stat('${s['unmarked'] ?? 0}', 'لم يُسجَّل')]),
      ),
      const SizedBox(height: 8),
      if (items.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('لا يوجد طلاب نشطون', style: TextStyle(color: Ya.muted)))),
      for (final it in items)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: YaCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Expanded(child: Text(it['fullName'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                if (it['joinedAt'] != null) Pill.ok('🔗 فتح الرابط ${ftime(DateTime.parse('${it['joinedAt']}').toLocal())}') else const Pill('لم يفتح الرابط', bg: Color(0xFFEDF1F3), fg: Ya.muted),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                for (final e in const [('PRESENT', '✅ حاضر', Ya.okBg, Ya.ok), ('ABSENT', '❌ غائب', Ya.dangerBg, Ya.danger), ('EXCUSED', '🤒 بعذر', Ya.warnBg, Ya.warn)])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: 8),
                      child: GestureDetector(
                        onTap: _busy ? null : () => _mark(it['studentId'] as String, it['status'] as String?, e.$1),
                        child: Container(
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: it['status'] == e.$1 ? e.$3 : Colors.white,
                            border: Border.all(color: it['status'] == e.$1 ? e.$3 : const Color(0xFFE8EEEC), width: 1.5),
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(13), topRight: Radius.circular(13), bottomRight: Radius.circular(13), bottomLeft: Radius.circular(5)),
                          ),
                          child: Text(e.$2, style: TextStyle(fontSize: 13.5, fontWeight: it['status'] == e.$1 ? FontWeight.w600 : FontWeight.w500, color: it['status'] == e.$1 ? e.$4 : Ya.muted)),
                        ),
                      ),
                    ),
                  ),
              ]),
            ]),
          ),
        ),
    ];
  }
}
