import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Opening screen: logo rises in over the same sky as the login screen, title follows, gold progress line fills.
class Splash extends StatefulWidget {
  const Splash({super.key, this.message});
  final String? message;
  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> with TickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 2300))..forward();
  late final AnimationController _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat(reverse: true);

  @override
  void dispose() {
    _in.dispose();
    _glow.dispose();
    super.dispose();
  }

  // 0..1 window of the intro timeline
  double _w(double a, double b, [Curve c = Curves.easeOutCubic]) => c.transform(((_in.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return NightSky(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedBuilder(
          animation: Listenable.merge([_in, _glow]),
          builder: (_, __) {
            final logo = _w(0.0, 0.42, Curves.easeOutBack);
            final logoFade = _w(0.0, 0.25);
            final title = _w(0.34, 0.62);
            final tag = _w(0.5, 0.78);
            final bar = _w(0.1, 1.0, Curves.easeInOutCubic);
            final g = Curves.easeInOut.transform(_glow.value);
            return Stack(children: [
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: Stack(alignment: Alignment.center, children: [
                      Opacity(
                        opacity: logoFade * (0.35 + 0.25 * g),
                        child: Container(
                          width: 250 + 20 * g,
                          height: 250 + 20 * g,
                          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0xFFF1CF85), Color(0x00F1CF85)])),
                        ),
                      ),
                      Opacity(
                        opacity: logoFade,
                        child: Transform.translate(
                          offset: Offset(0, 26 * (1 - logo)),
                          child: Transform.scale(scale: 0.7 + 0.3 * logo, child: Image.asset('assets/logo_t.png', width: 230)),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  Opacity(opacity: title, child: Transform.translate(offset: Offset(0, 14 * (1 - title)), child: Text('أكاديمية يارا', style: Ya.display(size: 36).copyWith(color: Colors.white)))),
                  const SizedBox(height: 6),
                  Opacity(opacity: tag, child: Transform.translate(offset: Offset(0, 10 * (1 - tag)), child: const Text('تعلّم مع معلمك، خطوة بخطوة', style: TextStyle(color: Color(0xFFB9C7DD), fontSize: 15)))),
                ]),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 90 + math.min(0, 0),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (widget.message != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(widget.message!, style: const TextStyle(color: Color(0xFFB9C7DD)))),
                  Opacity(
                    opacity: logoFade,
                    child: Container(
                      width: 150,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .55), borderRadius: BorderRadius.circular(5)),
                      alignment: AlignmentDirectional.centerStart,
                      child: FractionallySizedBox(
                        widthFactor: bar,
                        child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), gradient: const LinearGradient(colors: [Color(0xFFD8AE5F), Color(0xFFF1CF85)]))),
                      ),
                    ),
                  ),
                ]),
              ),
            ]);
          },
        ),
      ),
    );
  }
}
/// Night version of the login sky: deep blue gradient, stars, crescent moon, dark hills.
class NightSky extends StatelessWidget {
  const NightSky({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(children: [
        const Positioned.fill(child: CustomPaint(painter: _NightPainter())),
        child,
      ]);
}

class _NightPainter extends CustomPainter {
  const _NightPainter();
  @override
  void paint(Canvas canvas, Size s) {
    final rect = Offset.zero & s;
    canvas.drawRect(rect, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF070F24), Color(0xFF14284A), Color(0xFF244468)], stops: [0, .55, 1]).createShader(rect));
    final rnd = math.Random(11);
    for (var i = 0; i < 80; i++) {
      final p = Offset(rnd.nextDouble() * s.width, rnd.nextDouble() * s.height * .62);
      canvas.drawCircle(p, .5 + rnd.nextDouble() * 1.4, Paint()..color = Colors.white.withValues(alpha: .35 + rnd.nextDouble() * .6));
    }
    // moon sits where the sun will be on the login screen
    final c = Offset(s.width * .17, 112);
    canvas.drawCircle(c, 62, Paint()..color = const Color(0x22F4EBD0)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22));
    final moon = Path.combine(PathOperation.difference, Path()..addOval(Rect.fromCircle(center: c, radius: 32)), Path()..addOval(Rect.fromCircle(center: c.translate(15, -7), radius: 28)));
    canvas.drawPath(moon, Paint()..color = const Color(0xFFF4EBD0));
    final h = s.height;
    canvas.drawPath(
        Path()
          ..moveTo(0, h * .82)
          ..quadraticBezierTo(s.width * .3, h * .76, s.width * .62, h * .83)
          ..quadraticBezierTo(s.width * .85, h * .88, s.width, h * .8)
          ..lineTo(s.width, h)
          ..lineTo(0, h)
          ..close(),
        Paint()..color = const Color(0xFF16344A));
    canvas.drawPath(
        Path()
          ..moveTo(0, h * .9)
          ..quadraticBezierTo(s.width * .4, h * .85, s.width, h * .93)
          ..lineTo(s.width, h)
          ..lineTo(0, h)
          ..close(),
        Paint()..color = const Color(0xFF0E2536));
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// The academy brings the day: the logo glows, a sun rises from behind it and flies to its corner, light spreads out
/// from the sun over the night, and the logo lands in its place on the screen underneath.
class Dawn extends StatefulWidget {
  const Dawn({super.key, required this.child});
  final Widget child;
  static final GlobalKey logoKey = GlobalKey(debugLabel: 'dawn_logo');
  /// the screen underneath hides its own logo until the flying one has landed
  static final ValueNotifier<bool> landed = ValueNotifier<bool>(true);
  @override
  State<Dawn> createState() => _DawnState();
}

class _DawnState extends State<Dawn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));

  @override
  void initState() {
    super.initState();
    Dawn.landed.value = false;
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) Dawn.landed.value = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    Dawn.landed.value = true;
    _c.dispose();
    super.dispose();
  }

  double _w(double a, double b, Curve k) => k.transform(((_c.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final W = box.maxWidth, H = box.maxHeight;
        return AnimatedBuilder(
          animation: _c,
          builder: (_, child) {
            if (_c.value >= 1) return child!;
            // where the logo starts (splash) and where it lands (login)
            final start = Offset(W / 2, H / 2 - 41);
            var end = Offset(W / 2, H * .262);
            var endW = 150.0;
            final ro = Dawn.logoKey.currentContext?.findRenderObject();
            if (ro is RenderBox && ro.attached && ro.hasSize) {
              end = ro.localToGlobal(ro.size.center(Offset.zero));
              endW = ro.size.width;
            }
            final fly = _w(0.16, 0.78, Curves.easeInOutCubic);
            final logoC = Offset.lerp(start, end, fly)!;
            final logoW = 230 + (endW - 230) * fly;
            final glow = _w(0.0, 0.16, Curves.easeOut) * (1 - _w(0.3, 0.8, Curves.easeIn));
            // sun: grows behind the logo, then rises to its corner
            final grow = _w(0.04, 0.26, Curves.easeOutBack);
            final rise = _w(0.2, 0.82, Curves.easeInOutCubic);
            final sunC = Offset.lerp(start, Offset(W * .167, H * .1015), rise)!;
            final wipe = _w(0.16, 0.92, Curves.easeInOutCubic);
            final fade = 1 - _w(0.9, 1.0, Curves.easeIn);
            return Stack(children: [
              child!,
              // hide the day's own sun until the flying one has landed (otherwise two suns show)
              Positioned(
                left: W * .167 - W * .14,
                top: H * .1015 - W * .14,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: fade,
                    child: Container(width: W * .28, height: W * .28, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0xFFB6DEF2), Color(0xFFB6DEF2), Color(0x00B6DEF2)], stops: [0, .78, 1]))),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: ShaderMask(
                    blendMode: BlendMode.dstOut,
                    shaderCallback: (r) => RadialGradient(
                      center: Alignment(sunC.dx / W * 2 - 1, sunC.dy / H * 2 - 1),
                      radius: 3.6 * wipe + 0.001,
                      colors: const [Colors.white, Colors.white, Color(0x00FFFFFF)],
                      stops: const [0, 0.8, 1],
                    ).createShader(r),
                    child: const NightSky(child: SizedBox.expand()),
                  ),
                ),
              ),
              if (grow > 0)
                Positioned(
                  left: sunC.dx - W * .13 * grow,
                  top: sunC.dy - W * .13 * grow,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: fade,
                      child: Container(
                        width: W * .26 * grow,
                        height: W * .26 * grow,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: Color.lerp(const Color(0x66FFD04A), const Color(0xFFD5E3C8), rise)),
                        child: Container(width: W * .148 * grow, height: W * .148 * grow, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFD04A))),
                      ),
                    ),
                  ),
                ),
              Positioned(
                left: logoC.dx - 140,
                top: logoC.dy - 140,
                child: IgnorePointer(
                  child: SizedBox(
                    width: 280,
                    height: 280,
                    child: Stack(alignment: Alignment.center, children: [
                      Opacity(
                        opacity: glow * .6,
                        child: Container(width: 270, height: 270, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0xFFFFE6A8), Color(0x00FFE6A8)]))),
                      ),
                      Image.asset('assets/logo_t.png', width: logoW),
                    ]),
                  ),
                ),
              ),
            ]);
          },
          child: widget.child,
        );
      });
}