$ErrorActionPreference = 'Stop'
$base = 'E:\yara-academy-backend\yara_app\lib'
function Rep($file, $old, $new) {
  $p = Join-Path $base $file
  $t = [IO.File]::ReadAllText($p).Replace("`r`n", "`n")
  $c = ([regex]::Matches($t, [regex]::Escape($old))).Count
  if ($c -ne 1) { Write-Host "FAIL($c): $file :: $($old.Substring(0, [Math]::Min(60, $old.Length)))"; return }
  $t = $t.Replace($old, $new)
  [IO.File]::WriteAllText($p, $t)
}
function Imp($file, $imp) {
  $p = Join-Path $base $file
  $t = [IO.File]::ReadAllText($p).Replace("`r`n", "`n")
  if ($t -notmatch [regex]::Escape($imp)) { $t = $t.Replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';`n$imp"); [IO.File]::WriteAllText($p, $t) }
}
foreach ($f in 'screens\student_courses.dart','screens\student_subs.dart','screens\supervisor_requests.dart','screens\staff_courses.dart','screens\team_page.dart','screens\log_page.dart') { Imp $f "import 'tour.dart';" }
Imp 'core\widgets.dart' "import '../screens/tour.dart';"

Rep 'screens\student_courses.dart' "_Hero(first)," "Tour.wrap('hero', _Hero(first)),"
Rep 'screens\student_courses.dart' "child: ListView(scrollDirection: Axis.horizontal, children: [`n                        _chip('الكل'" "child: ListView(key: Tour.k('cats'), scrollDirection: Axis.horizontal, children: [`n                        _chip('الكل'"
Rep 'screens\student_courses.dart' "for (final c in list) Padding(padding: const EdgeInsets.only(bottom: 14), child: _CourseCard(c, onTap: () => _open(c)))," "for (final (i, c) in list.indexed) Padding(padding: const EdgeInsets.only(bottom: 14), child: Tour.wrap(i == 0 ? 'course0' : null, _CourseCard(c, onTap: () => _open(c))))," 
Rep 'screens\student_subs.dart' "final p = s.progress;`n                        return YaCard(" "final p = s.progress;`n                        return YaCard(`n                          key: i == 0 ? Tour.k('sub0') : null,"
Rep 'screens\supervisor_requests.dart' "child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(16, 12, 16, 6), children: [" "child: ListView(key: Tour.k('reqfilters'), scrollDirection: Axis.horizontal, padding: const EdgeInsets.fromLTRB(16, 12, 16, 6), children: ["
Rep 'screens\supervisor_requests.dart' "itemBuilder: (_, i) => _card(_subs[i])," "itemBuilder: (_, i) => Tour.wrap(i == 0 ? 'req0' : null, _card(_subs[i])),"
Rep 'screens\staff_courses.dart' "itemBuilder: (_, i) => _card(_courses[i])," "itemBuilder: (_, i) => Tour.wrap(i == 0 ? 'tcourse0' : null, _card(_courses[i])),"
Rep 'screens\staff_courses.dart' "                Row(children: [`n                  Expanded(child: GradButton(label: '＋ فئة جديدة'" "                Tour.wrap('catbtns', Row(children: [`n                  Expanded(child: GradButton(label: '＋ فئة جديدة'"
Rep 'screens\staff_courses.dart' "                ]),`n                if (_cats.isEmpty) const EmptyState(title: 'ابدئي" "                ])),`n                if (_cats.isEmpty) const EmptyState(title: 'ابدئي"
Rep 'screens\staff_courses.dart' "for (final c in list) Padding(padding: const EdgeInsets.only(top: 10), child: _card(c))," "for (final c in list) Padding(padding: const EdgeInsets.only(top: 10), child: Tour.wrap(identical(c, _courses.first) ? 'acourse0' : null, _card(c))),"
Rep 'screens\team_page.dart' "GradButton(label: '＋ معلمة جديدة', onPressed: _create)," "Tour.wrap('teambtn', GradButton(label: '＋ معلمة جديدة', onPressed: _create)),"
Rep 'screens\team_page.dart' "for (final u in _t) Padding(padding: const EdgeInsets.only(bottom: 12), child: _card(u))," "for (final u in _t) Padding(padding: const EdgeInsets.only(bottom: 12), child: Tour.wrap(identical(u, _t.first) ? 'team0' : null, _card(u))),"
Rep 'screens\log_page.dart' "child: ListView(scrollDirection: Axis.horizontal, children: [`n                    for (final e in const [('', 'الكل')" "child: ListView(key: Tour.k('logfilter'), scrollDirection: Axis.horizontal, children: [`n                    for (final e in const [('', 'الكل')"
Rep 'screens\log_page.dart' "YaCard(`n                  padding: const EdgeInsets.symmetric(vertical: 14)," "YaCard(`n                  key: Tour.k('logsum'),`n                  padding: const EdgeInsets.symmetric(vertical: 14),"
Rep 'core\widgets.dart' "child: GestureDetector(`n                behavior: HitTestBehavior.opaque,`n                onTap: () => onTap(i)," "child: GestureDetector(`n                key: Tour.k('nav`$i'),`n                behavior: HitTestBehavior.opaque,`n                onTap: () => onTap(i),"
Rep 'screens\home.dart' "        YaCard(`n          padding: const EdgeInsets.all(20)," "        YaCard(`n          key: Tour.k('acct'),`n          padding: const EdgeInsets.all(20),"
Rep 'screens\home.dart' "SoftButton(label: 'إعادة الجولة التعريفية', onPressed: onTour)," "Tour.wrap('redo', SoftButton(label: 'إعادة الجولة التعريفية', onPressed: onTour)),"
Write-Host done
