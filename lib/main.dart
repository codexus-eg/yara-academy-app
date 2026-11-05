import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/api.dart';
import 'core/auth.dart';
import 'core/theme.dart';
import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/splash.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final api = Api();
  final auth = AuthState(api)..boot();
  runApp(MultiProvider(
    providers: [Provider<Api>.value(value: api), ChangeNotifierProvider<AuthState>.value(value: auth)],
    child: const YaraApp(),
  ));
}

class YaraApp extends StatefulWidget {
  const YaraApp({super.key});
  @override
  State<YaraApp> createState() => _YaraAppState();
}

class _YaraAppState extends State<YaraApp> {
  bool _intro = true; // keep the splash on screen long enough to be seen

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _intro = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthState, AuthStatus>((a) => a.status);
    return MaterialApp(
      title: 'أكاديمية يارا',
      debugShowCheckedModeBanner: false,
      theme: Ya.theme(),
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: switch (status) {
          // checking the saved session: stay on a plain night-sky frame (no animation) so a signed-in user never sees the intro
          AuthStatus.booting => const NightSky(key: ValueKey('boot'), child: Scaffold(backgroundColor: Colors.transparent)),
          AuthStatus.offline => const Splash(key: ValueKey('splash'), message: 'بنحاول نتصل بالخادم…'),
          // already signed in: skip the timed intro and go straight to the app
          AuthStatus.signedIn => const HomeScreen(key: ValueKey('home')),
          _ when _intro => const Splash(key: ValueKey('splash')),
          AuthStatus.signedOut => const Dawn(key: ValueKey('login'), child: LoginScreen()),
        },
      ),
    );
  }
}