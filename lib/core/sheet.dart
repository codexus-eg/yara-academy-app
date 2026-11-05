import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'api.dart';
import 'theme.dart';
import 'widgets.dart';

/// Rounded website-style bottom sheet (handle + scroll + keyboard-safe). Provides the Api inside.
Future<T?> showYaSheet<T>(BuildContext context, WidgetBuilder builder) {
  final api = context.read<Api>();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (c) => Provider<Api>.value(
      value: api,
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(c).size.height * .9),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22, 10, 22, 20 + MediaQuery.of(c).viewInsets.bottom),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Center(child: Container(width: 44, height: 5, margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: Ya.line, borderRadius: BorderRadius.circular(3)))),
              Builder(builder: builder),
            ]),
          ),
        ),
      ),
    ),
  );
}

Future<bool> askConfirm(BuildContext context, String title, {String ok = 'تأكيد', String? body}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('رجوع')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(ok)),
      ],
    ),
  );
  return r == true;
}

/// Labelled field like the website's .field
class Field extends StatelessWidget {
  const Field(this.label, {super.key, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(label, style: const TextStyle(color: Ya.muted, fontSize: 13.5, fontWeight: FontWeight.w500))),
          child,
        ]),
      );
}

/// Holds the schedule picked in the approve / manual-enroll sheets.
class SchedController extends ChangeNotifier {
  final Set<int> days = {}; // 0 = Sunday … 6 = Saturday
  TimeOfDay time = const TimeOfDay(hour: 17, minute: 0);
  DateTime date = DateTime.now().add(const Duration(days: 1));
  bool trial = false;

  void toggle(int d) {
    days.contains(d) ? days.remove(d) : days.add(d);
    notifyListeners();
  }

  void setTrial(bool t) {
    trial = t;
    notifyListeners();
  }

  void setDate(DateTime d) {
    date = d;
    notifyListeners();
  }

  void setTime(TimeOfDay t) {
    time = t;
    notifyListeners();
  }

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// Returns the API body part or throws a String message.
  Map<String, dynamic> read() {
    final ds = trial ? {date.weekday % 7} : days;
    if (ds.isEmpty) throw 'اختر يوم واحد على الأقل';
    return {'days': ds.toList()..sort(), 'time': '${_two(time.hour)}:${_two(time.minute)}', 'startDate': '${date.year}-${_two(date.month)}-${_two(date.day)}'};
  }
}

const dayNames = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];

class SchedFields extends StatelessWidget {
  const SchedFields(this.c, {super.key});
  final SchedController c;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: c,
        builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (!c.trial)
            Field('أيام الحصص', child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (var i = 0; i < 7; i++) FilterPill(dayNames[i], selected: c.days.contains(i), onTap: () => c.toggle(i)),
            ])),
          Field('الوقت (بتوقيت الأكاديمية)', child: _pickBox(context, c.time.format(context), Icons.schedule_rounded, () async {
            final t = await showTimePicker(context: context, initialTime: c.time);
            if (t != null) c.setTime(t);
          })),
          Field(c.trial ? 'موعد الجلسة' : 'تاريخ أول حصة', child: _pickBox(context, fday(c.date), Icons.event_rounded, () async {
            final now = DateTime.now();
            final d = await showDatePicker(context: context, initialDate: c.date.isBefore(now) ? now : c.date, firstDate: now.subtract(const Duration(days: 1)), lastDate: now.add(const Duration(days: 365)));
            if (d != null) c.setDate(d);
          })),
        ]),
      );

  Widget _pickBox(BuildContext context, String text, IconData icon, VoidCallback f) => GestureDetector(
        onTap: f,
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE8EEEC), width: 1.5)),
          child: Row(children: [Expanded(child: Text(text, style: const TextStyle(fontSize: 15))), Icon(icon, color: Ya.muted, size: 20)]),
        ),
      );
}
