import 'package:flutter/material.dart';
import 'tour.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/auth.dart';
import '../core/live.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'course_sheet.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});
  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  List<Course> _courses = [];
  List<Map<String, dynamic>> _cats = [];
  String? _cat;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    context.read<Live>().addListener(_live);
    Tour.openCourse = () {
      final open = _courses.where((c) => c.mySub == null || const ['REJECTED', 'COMPLETED', 'CANCELLED'].contains(c.mySub!.status));
      if (open.isNotEmpty) _open(open.first);
    };
    Tour.closeSheet = () => Navigator.of(context).maybePop();
  }

  void _live() => _load();

  @override
  void dispose() {
    try { context.read<Live>().removeListener(_live); } catch (_) {}
    super.dispose();
  }

  Future<void> _load() async {
    final api = context.read<Api>();
    try {
      final r = await Future.wait([api.get('/courses'), api.get('/categories')]);
      if (!mounted) return;
      setState(() {
        _courses = ((r[0]['items'] as List?) ?? []).map((e) => Course(e as Map<String, dynamic>)).toList();
        _cats = ((r[1]['items'] as List?) ?? []).cast<Map<String, dynamic>>();
        _error = null;
        _loading = false;
      });
    } on ApiError catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _cat == null ? _courses : _courses.where((c) => c.categoryId == _cat).toList();
    final first = context.read<AuthState>().name.split(' ').first;
    return YaPage(
      title: 'الكورسات',
      child: _loading
          ? const Center(child: CircularProgressIndicator(color: Ya.teal))
          : _error != null
              ? Center(child: EmptyState(title: 'تعذّر تحميل الكورسات', hint: _error, mascot: 'robot', actionLabel: 'إعادة المحاولة', onAction: _load))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(padding: const EdgeInsets.fromLTRB(16, 14, 16, 16), children: [
                    Tour.wrap('hero', _Hero(first)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 38,
                      child: ListView(key: Tour.k('cats'), scrollDirection: Axis.horizontal, children: [
                        _chip('الكل', _cat == null, () => setState(() => _cat = null)),
                        for (final c in _cats) _chip(c['name'] as String, _cat == c['id'], () => setState(() => _cat = c['id'] as String)),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    if (list.isEmpty) const EmptyState(title: 'مفيش كورسات هنا', hint: 'جرّبي قسم تاني، أو ارجعي لـ «الكل».', mascot: 'fox'),
                    for (final (i, c) in list.indexed) Padding(padding: const EdgeInsets.only(bottom: 14), child: Tour.wrap(i == 0 ? 'course0' : null, _CourseCard(c, onTap: () => _open(c)))),
                  ]),
                ),
    );
  }

  Widget _chip(String t, bool sel, VoidCallback f) => Padding(
        padding: const EdgeInsetsDirectional.only(end: 8),
        child: FilterPill(t, selected: sel, onTap: f),
      );

  Future<void> _open(Course c) async {
    Tour.sheetOpen = true;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Provider<Api>.value(value: context.read<Api>(), child: CourseSheet(c)),
    );
    Tour.sheetOpen = false;
    _load();
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard(this.c, {required this.onTap});
  final Course c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return YaCard(
      edge: Ya.catColor(c.categoryId),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Ya.ink)),
          Text('${c.teacher?.name ?? ''} · ${c.totalSessions} حصص', style: const TextStyle(color: Ya.muted, fontSize: 13)),
          if (c.mySub != null) ...[
            const SizedBox(height: 8),
            _SubBadge(c.mySub!),
          ],
        ])),
        const SizedBox(width: 12),
        Column(children: [
          Text(c.price.toStringAsFixed(0), style: Ya.display(size: 26, color: Ya.strong).copyWith(height: 1.2)),
          Text(c.currency == 'SAR' ? 'ر.س' : c.currency, style: const TextStyle(fontSize: 12, color: Ya.muted)),
        ]),
      ]),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero(this.name);
  final String name;
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFFDCEBF1), Color(0xFFE3EFE8)]),
          borderRadius: BorderRadius.circular(26),
          boxShadow: Ya.cardShadow,
        ),
        child: Stack(clipBehavior: Clip.none, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('أهلاً $name', style: Ya.display(size: 26)),
            const SizedBox(height: 4),
            const SizedBox(width: 200, child: Text('اختر كورس وابدأ حصتك القادمة.', style: TextStyle(fontSize: 14, color: Color(0xFF33505F)))),
            const SizedBox(height: 14),
          ]),
          const PositionedDirectional(end: -4, bottom: -22, child: Mascot('owl', size: 92)),
        ]),
      );
}

class _SubBadge extends StatelessWidget {
  const _SubBadge(this.s);
  final MySub s;
  @override
  Widget build(BuildContext context) {
    final p = s.progress;
    final txt = s.status == 'ACTIVE' && p != null ? 'فعّال • ${p.done}/${p.total}' : (s.status == 'PENDING' ? 'قيد المراجعة' : s.status == 'AWAITING_PAYMENT' ? 'بانتظار الدفع' : s.status == 'COMPLETED' ? 'مكتمل' : s.status == 'REJECTED' ? 'مرفوض' : s.status == 'CANCELLED' ? 'ملغي' : s.status);
    return switch (s.status) {
      'ACTIVE' => Pill.ok(txt),
      'PENDING' => Pill.warn(txt),
      _ => Pill(txt),
    };
  }
}
