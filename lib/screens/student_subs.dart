import 'package:flutter/material.dart';
import 'tour.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/live.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'chat.dart';

class MySubsPage extends StatefulWidget {
  const MySubsPage({super.key});
  @override
  State<MySubsPage> createState() => _MySubsPageState();
}

class _MySubsPageState extends State<MySubsPage> {
  List<Subscription> _subs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    context.read<Live>().addListener(_live);
  }

  void _live() => _load();

  @override
  void dispose() {
    try { context.read<Live>().removeListener(_live); } catch (_) {}
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await context.read<Api>().get('/subscriptions/mine');
      if (!mounted) return;
      setState(() {
        _subs = ((r['items'] as List?) ?? []).map((e) => Subscription(e as Map<String, dynamic>)).where((s) => s.status != 'AWAITING_PAYMENT').toList();
        _loading = false;
      });
    } on ApiError catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        toast(context, e.message, error: true);
      }
    }
  }

  String _mood(int d, int t) => t == 0
      ? ''
      : d >= t
          ? '🏆 ما شاء الله، أنهيت كل حصصك!'
          : d >= t / 2
              ? '🔥 أداء ممتاز، $d من $t حصة'
              : d > 0
                  ? '🌱 بداية حلوة، $d من $t حصة'
                  : '🎒 مستعد؟ $t حصة في انتظارك';

  String? _next(Subscription s) {
    final list = (s.json['sessions'] as List?) ?? [];
    for (final x in list) {
      if (x is Map && x['doneAt'] == null && x['scheduledAt'] != null) {
        final d = DateTime.tryParse('${x['scheduledAt']}')?.toLocal();
        if (d == null) return null;
        return '${fday(d)} ${ftime(d)}';
      }
    }
    return null;
  }

  Future<void> _submit(Subscription s) async {
    try {
      await context.read<Api>().post('/subscriptions/${s.id}/submit');
      if (mounted) toast(context, 'تم إرسال طلبك للمراجعة، وراح نراجعه بأسرع وقت');
      _load();
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  Future<void> _cancel(Subscription s) async {
    try {
      await context.read<Api>().post('/subscriptions/${s.id}/cancel');
      _load();
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return YaPage(
      title: 'كورساتي',
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Ya.teal))
          : RefreshIndicator(
              onRefresh: _load,
              child: _subs.isEmpty
                  ? ListView(children: const [EmptyState(title: 'لسه مفيش اشتراكات', hint: 'اختر كورس من تبويب «الكورسات» وابدأ حصتك الأولى.', mascot: 'fox')])
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _subs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final s = _subs[i];
                        final p = s.progress;
                        return YaCard(
                          key: i == 0 ? Tour.k('sub0') : null,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                            Row(children: [
                              Expanded(child: Text(s.courseTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Ya.ink))),
                              switch (s.status) {
                                'ACTIVE' => Pill.ok(s.statusLabel),
                                'PENDING' => Pill.warn(s.statusLabel),
                                'REJECTED' || 'CANCELLED' => Pill.bad(s.statusLabel),
                                _ => Pill(s.statusLabel),
                              },
                            ]),
                            const SizedBox(height: 4),
                            Text('${s.typeLabel} · ${s.amount.toStringAsFixed(0)} ر.س', style: const TextStyle(color: Ya.muted, fontSize: 13)),
                            if (s.status == 'ACTIVE' && p != null) ...[
                              const SizedBox(height: 10),
                              Row(children: [
                                for (var k = 0; k < p.total; k++)
                                  Expanded(
                                    child: Container(
                                      height: 8,
                                      margin: const EdgeInsetsDirectional.only(end: 4),
                                      decoration: BoxDecoration(
                                        gradient: k < p.done ? Ya.btnGradient : null,
                                        color: k < p.done ? null : const Color(0xFFE8EEEC),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                              ]),
                              const SizedBox(height: 6),
                              Text(_mood(p.done, p.total), style: const TextStyle(fontSize: 12.5, color: Ya.muted)),
                              if (_next(s) != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text('الحصة القادمة: ${_next(s)}', style: const TextStyle(fontSize: 13, color: Ya.muted))),
                            ],
                            if (((s.json['rejectReason'] as String?) ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Ya.warnBg, borderRadius: BorderRadius.circular(14)), child: Text(s.json['rejectReason'] as String, style: const TextStyle(color: Ya.warn, fontSize: 14))),
                            ],
                            const SizedBox(height: 12),
                            if (s.status == 'ACTIVE')
                              GradButton(
                                icon: Icons.chat_bubble_outline_rounded,
                                label: 'الشات والحصة',
                                onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => ChatScreen(courseId: s.courseId, title: s.courseTitle))),
                              ),
                            if (s.status == 'AWAITING_PAYMENT') ...[
                              GradButton(label: '✅ أرسلت الرسالة على واتساب', height: 46, onPressed: () => _submit(s)),
                              const SizedBox(height: 8),
                            ],
                            if (s.status == 'AWAITING_PAYMENT' || s.status == 'PENDING')
                              SoftButton(label: s.status == 'PENDING' ? 'إلغاء الطلب' : 'إلغاء', height: 46, onPressed: () => _cancel(s)),
                          ]),
                        );
                      },
                    ),
            ),
    );
  }
}
