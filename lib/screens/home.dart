import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/api.dart';
import '../core/auth.dart';
import '../core/live.dart';
import '../core/sheet.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'log_page.dart';
import 'staff_courses.dart';
import 'student_courses.dart';
import 'student_subs.dart';
import 'supervisor_requests.dart';
import 'team_page.dart';
import 'tour.dart';

/// Role shell: student, teacher and supervisor tabs with the floating gold nav.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _i = 0;
  String _role = '';
  late final Live _live;

  @override
  void initState() {
    super.initState();
    _live = Live(context.read<Api>())
      ..onMessage = (m, {bool celebrate = false}) {
        if (mounted) toast(context, m);
      }
      ..connect();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 350));
      if (!mounted) return;
      final r = context.read<AuthState>().role;
      if (!await tourSeen(r) && mounted) _startTour();
    });
  }

  void _startTour() => showTour(context, context.read<AuthState>().role, (n) {
        if (mounted) setState(() => _i = n);
      });

  @override
  void dispose() {
    _live.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AuthState>();
    if (a.role != _role) {
      _role = a.role;
      _i = 0; // a different account starts on its first tab
    }
    final List<Widget> pages;
    final List<NavItem> items;
    const acct = NavItem('حسابي', Icons.person_outline_rounded);
    if (a.isStudent) {
      pages = [const CoursesPage(), const MySubsPage(), _Account(onTour: _startTour)];
      items = const [NavItem('الكورسات', Icons.menu_book_outlined), NavItem('كورساتي', Icons.school_outlined), acct];
    } else if (a.isTeacher) {
      pages = [const TeacherCoursesPage(), const LogPage(), _Account(onTour: _startTour)];
      items = const [NavItem('كورساتي', Icons.class_outlined), NavItem('السجل', Icons.list_alt_rounded), acct];
    } else {
      pages = [const RequestsPage(), const AdminCoursesPage(), const TeamPage(), const LogPage(), _Account(onTour: _startTour)];
      items = const [
        NavItem('الطلبات', Icons.payments_outlined),
        NavItem('الكورسات', Icons.class_outlined),
        NavItem('الفريق', Icons.groups_outlined),
        NavItem('السجل', Icons.list_alt_rounded),
        acct,
      ];
    }
    final i = _i.clamp(0, pages.length - 1);
    return ChangeNotifierProvider<Live>.value(
      value: _live,
      child: Container(
        decoration: const BoxDecoration(gradient: Ya.bgGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(children: [
            IndexedStack(index: i, children: pages),
            if (_role == 'STUDENT') const Positioned(left: 12, bottom: 12, child: HelpBuddy()),
          ]),
          bottomNavigationBar: YaNav(index: i, items: items, onTap: (v) => setState(() => _i = v)),
        ),
      ),
    );
  }
}

class _Account extends StatelessWidget {
  const _Account({required this.onTour});
  final VoidCallback onTour;

  Future<void> _profile(BuildContext context) async {
    final spec = TextEditingController(), bio = TextEditingController();
    final api = context.read<Api>();
    await showYaSheet<void>(
      context,
      (c) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('نبذتي', style: Ya.display(size: 25)),
        Field('التخصص', child: TextField(controller: spec)),
        Field('نبذة', child: TextField(controller: bio, maxLines: 4)),
        const SizedBox(height: 16),
        GradButton(
          label: 'حفظ',
          onPressed: () async {
            Navigator.pop(c);
            try {
              await api.put('/teachers/me/profile', body: {
                if (spec.text.trim().isNotEmpty) 'specialty': spec.text.trim(),
                if (bio.text.trim().isNotEmpty) 'bio': bio.text.trim(),
              });
              if (context.mounted) toast(context, 'تم الحفظ');
            } on ApiError catch (e) {
              if (context.mounted) toast(context, e.message, error: true);
            }
          },
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AuthState>();
    final roleLabel = const {'STUDENT': 'طالب', 'TEACHER': 'معلم', 'SUPERVISOR': 'مشرف'}[a.role] ?? '';
    return YaPage(
      title: 'حسابي',
      child: ListView(padding: const EdgeInsets.all(16), children: [
        YaCard(
          key: Tour.k('acct'),
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const Mascot('owl', size: 96),
            const SizedBox(height: 8),
            Text(a.name, textAlign: TextAlign.center, style: Ya.display(size: 24)),
            const SizedBox(height: 4),
            Text(roleLabel, style: const TextStyle(color: Ya.muted)),
            if (a.studentCode != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Ya.warnBg, borderRadius: BorderRadius.circular(14)),
                child: Column(children: [
                  Text('رقم الطالب: ${a.studentCode}', textDirection: TextDirection.ltr, style: const TextStyle(color: Ya.warn, fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 4),
                  const Text('احتفظ به، تستخدمه لتسجيل الدخول من أي جهاز.', textAlign: TextAlign.center, style: TextStyle(color: Ya.muted, fontSize: 13)),
                ]),
              ),
            ],
            if (a.isTeacher) ...[
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => _profile(context), child: const Text('تعديل نبذتي'))),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        Tour.wrap('support', GradButton(label: '💬 دعم واتساب', onPressed: openSupport)),
        const SizedBox(height: 10),
        Tour.wrap('redo', SoftButton(label: 'إعادة الجولة التعريفية', onPressed: onTour)),
        const SizedBox(height: 10),
        SoftButton(label: 'تسجيل الخروج', onPressed: a.signOut),
        if (a.isStudent) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () async {
              if (!await askConfirm(context, 'حذف حسابي؟', ok: 'حذف', body: 'هتتحذف بياناتك واشتراكاتك الجارية نهائيًا ومينفعش ترجع.')) return;
              if (!context.mounted) return;
              try {
                await context.read<Api>().delete('/auth/me');
                if (context.mounted) toast(context, 'تم حذف حسابك');
                await a.signOut();
              } on ApiError catch (e) {
                if (context.mounted) toast(context, e.message, error: true);
              }
            },
            child: const Text('حذف حسابي'),
          ),
        ],
        const SizedBox(height: 6),
        TextButton(onPressed: openPrivacy, child: const Text('سياسة الخصوصية', style: TextStyle(color: Ya.muted, fontSize: 13))),
      ]),
    );
  }
}


Future<void> openPrivacy() => launchUrl(Uri.parse('https://yaraacademy.tech/privacy'), mode: LaunchMode.externalApplication);

Future<void> openSupport() => openSupportWith('السلام عليكم، عندي سؤال بخصوص أكاديمية يارا');

Future<void> openSupportWith(String text) => launchUrl(Uri.parse('https://wa.me/201014206851?text=${Uri.encodeComponent(text)}'), mode: LaunchMode.externalApplication);

/// Floating helper animal: tap to chat with support on WhatsApp.
class HelpBuddy extends StatefulWidget {
  const HelpBuddy({super.key});
  @override
  State<HelpBuddy> createState() => _HelpBuddyState();
}

class _HelpBuddyState extends State<HelpBuddy> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat(reverse: true);
  bool _bubble = true;
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 7), () { if (mounted) setState(() => _bubble = false); });
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Tour.wrap('helpbuddy', GestureDetector(
      onTap: openSupport,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        AnimatedBuilder(
          animation: _c,
          builder: (_, child) => Transform.translate(offset: Offset(0, -5 * Curves.easeInOut.transform(_c.value)), child: child),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF25D366), width: 2.5), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 3))]),
            child: const Mascot('fox', size: 46),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          child: _bubble
              ? Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFF25D366), borderRadius: BorderRadius.circular(14)),
                  child: const Text('محتاج مساعدة؟ كلّمنا واتساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                )
              : const SizedBox.shrink(),
        ),
      ]),
    ));
  }
}
