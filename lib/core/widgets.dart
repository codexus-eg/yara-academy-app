import 'package:flutter/material.dart';
import '../screens/tour.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'theme.dart';

/// Page frame used by every screen: gradient background + frosted rounded header.
class YaPage extends StatelessWidget {
  const YaPage({super.key, required this.title, required this.child, this.back = false, this.actions = const [], this.bottom, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;
  final bool back;
  final List<Widget> actions;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(gradient: Ya.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(children: [
          Container(
            padding: EdgeInsets.fromLTRB(10, top + 10, 14, 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .85),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
              boxShadow: [BoxShadow(color: const Color(0xFF1F5A73).withValues(alpha: .08), blurRadius: 18, offset: const Offset(0, 6))],
            ),
            child: Row(children: [
              if (back)
                IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_forward_rounded, color: Ya.ink))
              else
                const SizedBox(width: 6),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Ya.display(size: 26)),
                  if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 12.5, color: Ya.muted)),
                ]),
              ),
              ...actions,
            ]),
          ),
          Expanded(child: child),
          if (bottom != null) bottom!,
        ]),
      ),
    );
  }
}

/// White card with hairline border and soft shadow; optional coloured start edge (course category).
class YaCard extends StatelessWidget {
  const YaCard({super.key, required this.child, this.edge, this.onTap, this.padding = const EdgeInsets.all(15)});
  final Widget child;
  final Color? edge;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(20);
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: r, border: Border.all(color: Ya.line), boxShadow: Ya.cardShadow),
      child: ClipRRect(
        borderRadius: r,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Container(
              decoration: edge == null ? null : BoxDecoration(border: BorderDirectional(start: BorderSide(color: edge!, width: 6))),
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Teal gradient button, coloured shadow, smaller bottom corner (like the website's .btn)
class GradButton extends StatelessWidget {
  const GradButton({super.key, required this.label, required this.onPressed, this.icon, this.gradient = Ya.btnGradient, this.busy = false, this.height = 48});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Gradient gradient;
  final bool busy;
  final double height;

  @override
  Widget build(BuildContext context) {
    const r = BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomRight: Radius.circular(16), bottomLeft: Radius.circular(6));
    final off = onPressed == null;
    final glow = gradient == Ya.waGradient ? const Color(0xFF128C4A) : Ya.teal;
    return Opacity(
      opacity: off ? .5 : 1,
      child: Container(
        height: height,
        decoration: BoxDecoration(gradient: gradient, borderRadius: r, boxShadow: [BoxShadow(color: glow.withValues(alpha: .28), blurRadius: 16, offset: const Offset(0, 8))]),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: r,
            onTap: busy ? null : onPressed,
            child: Center(
              child: busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      if (icon != null) ...[Icon(icon, color: Colors.white, size: 19), const SizedBox(width: 8)],
                      Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft button (pink "reject", plain secondary…)
class SoftButton extends StatelessWidget {
  const SoftButton({super.key, required this.label, required this.onPressed, this.bg = Ya.dangerBg, this.fg = Ya.danger, this.height = 48});
  final String label;
  final VoidCallback? onPressed;
  final Color bg, fg;
  final double height;

  @override
  Widget build(BuildContext context) {
    const r = BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16), bottomRight: Radius.circular(16), bottomLeft: Radius.circular(6));
    return Material(
      color: bg,
      borderRadius: r,
      child: InkWell(
        borderRadius: r,
        onTap: onPressed,
        child: SizedBox(height: height, child: Center(child: Text(label, style: TextStyle(color: fg, fontSize: 15, fontWeight: FontWeight.w600)))),
      ),
    );
  }
}

/// Pastel pill (status chips)
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.bg = Ya.soft, this.fg = Ya.strong});
  final String text;
  final Color bg, fg;
  factory Pill.ok(String t) => Pill(t, bg: Ya.okBg, fg: Ya.ok);
  factory Pill.warn(String t) => Pill(t, bg: Ya.warnBg, fg: Ya.warn);
  factory Pill.bad(String t) => Pill(t, bg: Ya.dangerBg, fg: Ya.danger);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: TextStyle(color: fg, fontSize: 12.5, fontWeight: FontWeight.w600)),
      );
}

/// Filter chip (website style: white pill with border, active = teal gradient)
class FilterPill extends StatelessWidget {
  const FilterPill(this.label, {super.key, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? Ya.btnGradient : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(19),
            border: selected ? null : Border.all(color: const Color(0xFFE8EEEC)),
          ),
          child: Text(label, style: TextStyle(color: selected ? Colors.white : Ya.ink, fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w500)),
        ),
      );
}

/// Segmented progress (one bar per session; a solid bar for long courses)
class Segs extends StatelessWidget {
  const Segs(this.done, this.total, {super.key});
  final int done, total;
  @override
  Widget build(BuildContext context) {
    if (total <= 0) return const SizedBox.shrink();
    if (total > 24) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(children: [
          Container(height: 8, color: const Color(0xFFE8EEEC)),
          FractionallySizedBox(widthFactor: (done / total).clamp(0, 1), child: Container(height: 8, decoration: const BoxDecoration(gradient: Ya.btnGradient))),
        ]),
      );
    }
    return Row(children: [
      for (var k = 0; k < total; k++)
        Expanded(
          child: Container(
            height: 8,
            margin: const EdgeInsetsDirectional.only(end: 4),
            decoration: BoxDecoration(gradient: k < done ? Ya.btnGradient : null, color: k < done ? null : const Color(0xFFE8EEEC), borderRadius: BorderRadius.circular(4)),
          ),
        ),
    ]);
  }
}

class NavItem {
  const NavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Floating bottom bar with a gold active pill
class YaNav extends StatelessWidget {
  const YaNav({super.key, required this.index, required this.items, required this.onTap});
  final int index;
  final List<NavItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final n = items.length;
    const h = 54.0;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: [BoxShadow(color: const Color(0xFF1F5A73).withValues(alpha: .12), blurRadius: 18, offset: const Offset(0, 6))]),
        child: SizedBox(
          height: h,
          child: Stack(children: [
            // gold pill that glides to the selected tab
            AnimatedAlign(
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutBack,
              alignment: AlignmentDirectional(n <= 1 ? 0 : -1 + 2 * index / (n - 1), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                heightFactor: 1,
                child: Container(decoration: BoxDecoration(color: Ya.gold, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Ya.gold.withValues(alpha: .45), blurRadius: 12, offset: const Offset(0, 4))])),
              ),
            ),
            Row(children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: GestureDetector(
                    key: Tour.k('nav$i'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: _NavCell(item: items[i], selected: i == index),
                  ),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _NavCell extends StatelessWidget {
  const _NavCell({required this.item, required this.selected});
  final NavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = selected ? Ya.ink : const Color(0xFF6B7A88);
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      AnimatedSlide(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutBack,
        offset: selected ? const Offset(0, -0.06) : Offset.zero,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutBack,
          scale: selected ? 1.22 : 1.0,
          child: TweenAnimationBuilder<Color?>(
            duration: const Duration(milliseconds: 250),
            tween: ColorTween(end: c),
            builder: (_, v, _) => Icon(item.icon, size: 22, color: v),
          ),
        ),
      ),
      const SizedBox(height: 1),
      AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 250),
        style: TextStyle(fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily, fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w400, color: c),
        child: Text(item.label),
      ),
    ]);
  }
}

// ---- mascots (flat SVG, same family as the website's owl / fox / robot) ----
const _owl = '''<svg viewBox="0 0 84 84" xmlns="http://www.w3.org/2000/svg"><ellipse cx="42" cy="52" rx="32" ry="30" fill="#A57B58"/><ellipse cx="42" cy="62" rx="20" ry="18" fill="#F3E6D3"/><circle cx="31" cy="44" r="11" fill="#fff"/><circle cx="53" cy="44" r="11" fill="#fff"/><circle cx="33" cy="46" r="5" fill="#2A1F18"/><circle cx="51" cy="46" r="5" fill="#2A1F18"/><path d="M38 53 L46 53 L42 60 Z" fill="#F2A33A"/><path d="M12 28 L42 15 L72 28 L42 40 Z" fill="#2A3F5F"/><path d="M68 30 V44" stroke="#F2B84B" stroke-width="2.5"/><circle cx="68" cy="46" r="3" fill="#F2B84B"/></svg>''';
const _fox = '''<svg viewBox="0 0 62 64" xmlns="http://www.w3.org/2000/svg"><path d="M6 6 L22 22 L40 22 L56 6 L58 40 Q58 60 31 60 Q4 60 4 40 Z" fill="#E8833A"/><path d="M12 14 L21 24 L12 30 Z M52 14 L43 24 L52 30 Z" fill="#F8D9B8"/><ellipse cx="31" cy="46" rx="20" ry="13" fill="#FBEBD6"/><circle cx="21" cy="36" r="3.5" fill="#2A1F18"/><circle cx="41" cy="36" r="3.5" fill="#2A1F18"/><ellipse cx="31" cy="44" rx="4" ry="3" fill="#2A1F18"/></svg>''';
const _robot = '''<svg viewBox="0 0 60 84" xmlns="http://www.w3.org/2000/svg"><rect x="6" y="14" width="48" height="40" rx="14" fill="#CFE0F3"/><rect x="12" y="22" width="36" height="20" rx="9" fill="#2A3F5F"/><circle cx="23" cy="32" r="4" fill="#54D1F0"/><circle cx="37" cy="32" r="4" fill="#54D1F0"/><rect x="28" y="4" width="4" height="12" rx="2" fill="#9DB4CF"/><circle cx="30" cy="4" r="4" fill="#F2B84B"/><rect x="14" y="52" width="32" height="28" rx="12" fill="#B7CCE6"/></svg>''';
const _sky = '''<svg viewBox="0 0 390 844" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMidYMid slice"><circle cx="70" cy="86" r="42" fill="#FFE07A" opacity=".35"/><circle cx="70" cy="86" r="28" fill="#FFD04D"/><g fill="#fff" opacity=".9"><path d="M290 70 q0-20 22-20 q8-14 26-6 q20-2 22 16 q14 2 10 18 H296 q-10-2-6-8z"/><path d="M168 150 q0-12 14-12 q6-10 18-4 q14-1 15 11 q10 1 7 12 H172 q-7-1-4-7z" opacity=".8"/></g><path d="M0 700 Q120 640 250 690 T390 660 V844 H0 Z" fill="#7CCB92"/><path d="M0 760 Q150 710 300 750 T390 735 V844 H0 Z" fill="#5DB87B"/></svg>''';
const _shield = '''<svg viewBox="0 0 104 118" xmlns="http://www.w3.org/2000/svg"><path d="M52 4 L98 18 V58 C98 84 78 104 52 114 C26 104 6 84 6 58 V18 Z" fill="#1F4E68"/><path d="M52 12 L90 24 V58 C90 79 74 96 52 105 C30 96 14 79 14 58 V24 Z" fill="none" stroke="#D4A24C" stroke-width="1.5"/><path d="M34 42 H50 V66 H34 Z M54 42 H70 V66 H54 Z" fill="none" stroke="#D4A24C" stroke-width="2" stroke-linejoin="round"/><path d="M40 80 L52 74 L64 80 L52 86 Z" fill="#D4A24C"/></svg>''';

/// Friendly empty state: mascot + title + hint (+ optional action)
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, this.hint, this.mascot = 'owl', this.actionLabel, this.onAction});
  final String title;
  final String? hint;
  final String mascot;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 48, 28, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 150, height: 150,
            alignment: Alignment.center,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft, colors: [Color(0xFFDCEBF1), Color(0xFFE3EFE8)])),
            child: Mascot(mascot, size: 96),
          ),
          const SizedBox(height: 18),
          Text(title, textAlign: TextAlign.center, style: Ya.display(size: 24)),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(hint!, textAlign: TextAlign.center, style: const TextStyle(color: Ya.muted, fontSize: 14, height: 1.7)),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: 18),
            SizedBox(width: 220, child: GradButton(label: actionLabel!, onPressed: onAction)),
          ],
        ]),
      );
}

class Mascot extends StatelessWidget {
  const Mascot(this.kind, {super.key, this.size = 80});
  final String kind; // owl | fox | robot | sky | shield
  final double size;
  @override
  Widget build(BuildContext context) {
    final s = switch (kind) { 'fox' => _fox, 'robot' => _robot, 'sky' => _sky, 'shield' => _shield, _ => _owl };
    return SvgPicture.string(s, height: size);
  }
}

class SkyBackground extends StatelessWidget {
  const SkyBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA9D8F0), Color(0xFFD9EEF8), Color(0xFFEAF4F2)], stops: [0, .38, .62])),
        child: Stack(children: [
          Positioned.fill(child: SvgPicture.string(_sky, fit: BoxFit.cover, alignment: Alignment.bottomCenter)),
          child,
        ]),
      );
}
