import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'chat.dart';
import 'tour.dart';

/// Same emoji mapping as the website (subjectEmoji)
String subjectEmoji(String? name) {
  final n = name ?? '';
  const rules = <List<String>>[
    ['قرآن|قران|تجويد|حفظ|تلاوة', '📖'], ['إسلام|اسلام|فقه|سيرة|حديث|عقيدة|دين', '🕌'],
    ['عربي|عربية|نحو|إملاء|املاء|بلاغة|قراءة', '✍️'], ['رياضيات|حساب|جبر|هندسة', '➗'],
    ['إنجليز|انجليز|english', '🌍'], ['فرنس', '🥖'], ['ألماني|الماني', '🥨'], ['علوم|science', '🔬'],
    ['فيزياء', '⚛️'], ['كيمياء', '🧪'], ['أحياء|احياء', '🧬'], ['تاريخ', '🏛️'], ['جغرافيا', '🗺️'],
    ['حاسب|برمجة|كمبيوتر|تقنية', '💻'], ['رسم|فن|تلوين', '🎨'], ['موسيق|غناء', '🎵'], ['رياض|لياقة', '⚽'], ['مهارات|تنمية', '🌟'],
  ];
  for (final r in rules) {
    if (RegExp(r[0], caseSensitive: false).hasMatch(n)) return r[1];
  }
  return '📚';
}

class _Opt {
  const _Opt(this.type, this.emoji, this.title, this.sub);
  final String type, emoji, title, sub;
}

String _cur(String c) => const {'SAR': 'ر.س', 'EGP': 'ج.م', 'USD': r'$'}[c] ?? c;
String _money(double v) => (v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2));

/// Course details + booking, mirroring the website's course sheet.
class CourseSheet extends StatefulWidget {
  const CourseSheet(this.c, {super.key});
  final Course c;
  @override
  State<CourseSheet> createState() => _CourseSheetState();
}

class _CourseSheetState extends State<CourseSheet> {
  late String _type;
  late int _n;
  bool _busy = false;

  Course get c => widget.c;

  List<_Opt> get _opts => [
        if (c.trialAvailable && !c.trialUsed) const _Opt('TRIAL', '🎁', 'جلسة تجريبية', 'حصة واحدة مجانية تجرّب فيها المعلم'),
        if (c.packagesAvailable && c.totalSessions > 1)
          _Opt('PACKAGE', '📦', 'باقة حصص', '${_money(c.pricePerSession)} ${_cur(c.currency)} للحصة، اختر العدد اللي يناسبك'),
        _Opt('FULL', '🎓', 'الكورس كامل', '${c.totalSessions} حصة'),
      ];

  @override
  void initState() {
    super.initState();
    _type = _opts.any((o) => o.type == 'FULL') ? 'FULL' : _opts.first.type;
    _n = (c.totalSessions - 1).clamp(1, 4);
  }

  double get _price {
    if (_type == 'TRIAL') return 0;
    final p = _type == 'TRIAL' ? c.trialPrice : _type == 'FULL' ? c.price : c.pricePerSession * _n;
    return (p * 100).roundToDouble() / 100;
  }

  Future<void> _book() async {
    final api = context.read<Api>();
    setState(() => _busy = true);
    try {
      final r = await api.post('/subscriptions', body: {
        'courseId': c.id,
        'type': _type,
        if (_type == 'PACKAGE') 'sessions': _n,
      });
      // The request goes to the supervisor right away: no "awaiting payment" step, no confirmation.
      final id = (r['subscription'] as Map)['id'] as String;
      if ((r['subscription'] as Map)['status'] == 'AWAITING_PAYMENT') await api.post('/subscriptions/$id/submit');
      final url = r['whatsappUrl'] as String?;
      if (mounted) {
        toast(context, 'تم إرسال طلبك للمشرف 🎉');
        Navigator.pop(context);
      }
      if (url != null) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(22, 10, 22, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width: 44, height: 5, margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: Ya.line, borderRadius: BorderRadius.circular(3)))),
          ..._detail(),
        ]),
      ),
    );
  }

  List<Widget> _detail() {
    final ms = c.mySub;
    final Widget action;
    if (ms?.status == 'ACTIVE') {
      action = GradButton(
        label: '💬 ادخل المحادثة',
        onPressed: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ChatScreen(courseId: c.id, title: c.title)));
        },
      );
    } else if (ms?.status == 'PENDING') {
      action = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: Ya.warnBg, borderRadius: BorderRadius.circular(14)),
        child: const Text('⏳ طلبك قيد المراجعة، راح يوصلك إشعار أول ما نوافق عليه.', style: TextStyle(color: Ya.warn, fontSize: 14)),
      );
    } else {
      action = _booking();
    }
    return [
      Text('${subjectEmoji(c.categoryName)} ${c.title}', style: Ya.display(size: 25)),
      Text('${c.categoryName} · ${c.totalSessions} حصة', style: const TextStyle(color: Ya.muted, fontSize: 14)),
      if (c.description.isNotEmpty) ...[const SizedBox(height: 10), Text(c.description, style: const TextStyle(height: 1.7))],
      if (c.teacher != null) ...[
        const SizedBox(height: 10),
        YaCard(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: Ya.soft, borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14), bottomRight: Radius.circular(14), bottomLeft: Radius.circular(5))),
              child: Text(c.teacher!.name.isEmpty ? '' : c.teacher!.name[0], style: const TextStyle(color: Ya.strong, fontWeight: FontWeight.w700, fontSize: 17)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.teacher!.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              if ((c.teacher!.specialty ?? '').isNotEmpty) Text(c.teacher!.specialty!, style: const TextStyle(color: Ya.muted, fontSize: 13)),
            ])),
          ]),
        ),
      ],
      const SizedBox(height: 12),
      action,
    ];
  }

  Widget _booking() {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Tour.wrap('bk_opts', Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final o in _opts) ...[_optTile(o), const SizedBox(height: 10)]])),
      const SizedBox(height: 2),
      Tour.wrap('bk_btn', GradButton(
        label: _price == 0 ? '💬 احجز الجلسة المجانية عبر واتساب' : '💬 احجز عبر واتساب · ${_money(_price)} ${_cur(c.currency)}',
        gradient: Ya.waGradient,
        busy: _busy,
        onPressed: _busy ? null : _book,
      )),
      const SizedBox(height: 8),
      const Text('يوصل طلبك للمشرف فوراً، ويفتح لك واتساب برسالة جاهزة للدفع.', textAlign: TextAlign.center, style: TextStyle(color: Ya.muted, fontSize: 13)),
    ]);
  }

  Widget _optTile(_Opt o) {
    final on = _type == o.type;
    return GestureDetector(
      onTap: () => setState(() => _type = o.type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: on ? Ya.soft : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: on ? Ya.teal : Ya.line, width: 2),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 46, height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: on ? Colors.white : Ya.soft, borderRadius: BorderRadius.circular(15)),
            child: Text(o.emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(o.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
            Text(o.sub, style: const TextStyle(color: Ya.muted, fontSize: 13, height: 1.5)),
            if (o.type == 'PACKAGE' && on) _stepper(),
          ])),
          const SizedBox(width: 8),
          Container(
            width: 26, height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: on ? Ya.teal : Colors.transparent, border: Border.all(color: on ? Ya.teal : Ya.line, width: 2)),
            child: on ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
          ),
        ]),
      ),
    );
  }

  Widget _stepper() {
    final max = c.totalSessions - 1;
    Widget btn(String t, int d) => GestureDetector(
          onTap: () => setState(() => _n = (_n + d).clamp(1, max)),
          child: Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: Ya.soft, borderRadius: BorderRadius.circular(10)), child: Text(t, style: const TextStyle(color: Ya.strong, fontSize: 20, fontWeight: FontWeight.w700))),
        );
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: Ya.line, width: 1.5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        btn('−', -1),
        SizedBox(width: 78, child: Text('$_n ${_n <= 10 ? 'حصص' : 'حصة'}', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))),
        btn('+', 1),
      ]),
    );
  }
}
