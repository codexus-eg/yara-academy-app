import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/auth.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import 'home.dart' show HelpBuddy, openPrivacy;
import 'splash.dart' show Dawn;
import 'tour.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _code = TextEditingController();
  final _name = TextEditingController();
  bool _register = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 3600), () async {
      if (mounted && !await tourSeen('LOGIN') && mounted) _tour();
    });
  }

  void _tour() => showTour(context, 'LOGIN', (_) {});

  Future<void> _submit() async {
    final auth = context.read<AuthState>();
    final v = (_register ? _name : _code).text.trim();
    if (v.isEmpty) return;
    setState(() => _busy = true);
    try {
      if (_register) {
        await auth.register(v);
        if (mounted) await _showCode(auth.studentCode);
      } else {
        await auth.login(v);
      }
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showCode(String? code) async {
    if (code == null) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text('أهلاً بيك في أكاديمية يارا', textAlign: TextAlign.center, style: Ya.display(size: 22)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('ده كودك للدخول، احتفظ بيه:', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(code, style: Ya.display(size: 38, color: Ya.teal).copyWith(letterSpacing: 6)),
        ]),
        actions: [
          TextButton(onPressed: () => Clipboard.setData(ClipboardData(text: code)), child: const Text('نسخ')),
          FilledButton(onPressed: () => Navigator.pop(c), child: const Text('تمام')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SkyBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: const HelpBuddy(),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Center(child: ValueListenableBuilder<bool>(valueListenable: Dawn.landed, builder: (_, v, c) => Opacity(opacity: v ? 1 : 0, child: c), child: KeyedSubtree(key: Dawn.logoKey, child: Image.asset('assets/logo_t.png', height: 150)))),
                  const SizedBox(height: 8),
                  Text('أكاديمية يارا', textAlign: TextAlign.center, style: Ya.display(size: 32)),
                  const SizedBox(height: 4),
                  const Text('تعلّم مع معلمك، خطوة بخطوة', textAlign: TextAlign.center, style: TextStyle(color: Ya.muted)),
                  const SizedBox(height: 22),
                  YaCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      if (_register)
                        TextField(
                          controller: _name,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(labelText: 'الاسم الرباعي'),
                        )
                      else
                        Tour.wrap('lg_code', TextField(
                          controller: _code,
                          textAlign: TextAlign.center,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          style: const TextStyle(fontSize: 22, letterSpacing: 4, fontWeight: FontWeight.w700),
                          decoration: const InputDecoration(labelText: 'كود الدخول'),
                        )),
                      const SizedBox(height: 14),
                      Tour.wrap('lg_btn', GradButton(label: _register ? 'إنشاء حساب' : 'دخول', busy: _busy, onPressed: _busy ? null : _submit)),
                      const SizedBox(height: 4),
                      Tour.wrap('lg_reg', TextButton(
                        onPressed: () => setState(() => _register = !_register),
                        child: Text(_register ? 'عندي كود بالفعل' : 'طالب جديد؟ سجّل'),
                      )),
                    ]),
                  ),
                  TextButton(onPressed: _tour, child: const Text('جولة سريعة في التطبيق')),
          TextButton(onPressed: openPrivacy, child: const Text('سياسة الخصوصية', style: TextStyle(color: Ya.muted, fontSize: 13))),
                  const SizedBox(height: 6),
                  const Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Mascot('robot', size: 78),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
