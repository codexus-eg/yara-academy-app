import 'package:flutter/material.dart';
import 'dart:async';
import 'tour.dart';
import 'package:provider/provider.dart';

import '../core/api.dart';
import '../core/live.dart';
import '../core/models.dart';
import '../core/sheet.dart';
import '../core/theme.dart';
import '../core/widgets.dart';

/// Supervisor: subscription requests with search, approve (with schedule) and reject (with reason).
class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});
  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  List<Subscription> _subs = [];
  List<Map<String, dynamic>> _teachers = [];
  final _q = TextEditingController();
  Timer? _deb;
  bool _loading = true;

  Api get _api => context.read<Api>();

  @override
  void initState() {
    super.initState();
    _load();
    context.read<Live>().addListener(_live);
  }

  void _live() => _load();

  @override
  void dispose() {
    _deb?.cancel();
    _q.dispose();
    try { context.read<Live>().removeListener(_live); } catch (_) {}
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await Future.wait([_api.get('/subscriptions', query: {'limit': 100, if (_q.text.trim().isNotEmpty) 'q': _q.text.trim()}), _api.get('/staff/teachers')]);
      if (!mounted) return;
      setState(() {
        final all = ((r[0]['items'] as List?) ?? []).map((e) => Subscription(e as Map<String, dynamic>)).where((s) => s.status != 'AWAITING_PAYMENT' && s.status != 'CANCELLED').toList();
        _subs = [...all.where((s) => s.status == 'PENDING'), ...all.where((s) => s.status != 'PENDING')]; // waiting-for-review first

        _teachers = ((r[1]['items'] as List?) ?? []).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } on ApiError catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        toast(context, e.message, error: true);
      }
    }
  }

  Future<void> _approve(Subscription s) async {
    final sched = SchedController()..trial = s.type == 'TRIAL';
    String? teacherId;
    await showYaSheet<void>(
      context,
      (c) => StatefulBuilder(
        builder: (c, set) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('الموافقة على الاشتراك', style: Ya.display(size: 25)),
          const SizedBox(height: 4),
          Text('${(s.json['student'] as Map?)?['fullName'] ?? ''} · ${s.courseTitle} · ${s.typeLabel} (${s.sessionsTotal} حصة)', style: const TextStyle(color: Ya.muted, height: 1.6)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Ya.warnBg, borderRadius: BorderRadius.circular(14)),
            child: Text('تأكدي من وصول المبلغ ${s.amount.toStringAsFixed(0)} على واتساب قبل الموافقة.', style: const TextStyle(color: Ya.warn, height: 1.5)),
          ),
          Field('المعلم', child: DropdownButtonFormField<String?>(
            initialValue: teacherId,
            isExpanded: true,
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('معلم الكورس (الافتراضية)')),
              for (final t in _teachers.where((t) => t['isActive'] == true)) DropdownMenuItem<String?>(value: t['id'] as String, child: Text(t['fullName'] as String)),
            ],
            onChanged: (v) => set(() => teacherId = v),
          )),
          SchedFields(sched),
          const SizedBox(height: 16),
          GradButton(
            label: 'موافقة وتوليد الحصص',
            onPressed: () async {
              Map<String, dynamic> body;
              try {
                body = sched.read();
              } on String catch (m) {
                toast(c, m, error: true);
                return;
              }
              if (teacherId != null) body['teacherId'] = teacherId;
              Navigator.pop(c);
              try {
                await _api.post('/subscriptions/${s.id}/approve', body: body);
                if (mounted) toast(context, 'تمت الموافقة');
                _load();
              } on ApiError catch (e) {
                if (mounted) toast(context, e.message, error: true);
              }
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _reject(Subscription s) async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('سبب الرفض (اختياري)'),
        content: TextField(controller: reason, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('رجوع')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('رفض')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _api.post('/subscriptions/${s.id}/reject', body: {'reason': reason.text.trim()});
      if (mounted) toast(context, 'تم رفض الطلب');
      _load();
    } on ApiError catch (e) {
      if (mounted) toast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return YaPage(
      title: 'الطلبات',
      child: Column(children: [
        Padding(
          key: Tour.k('reqsearch'),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _q,
            textInputAction: TextInputAction.search,
            onChanged: (_) {
              _deb?.cancel();
              _deb = Timer(const Duration(milliseconds: 350), _load);
              setState(() {});
            },
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم أو رقم الطالب',
              prefixIcon: const Icon(Icons.search_rounded, color: Ya.muted),
              suffixIcon: _q.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded, color: Ya.muted),
                      onPressed: () {
                        _q.clear();
                        setState(() {});
                        _load();
                      },
                    ),
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Ya.teal))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _subs.isEmpty
                      ? ListView(children: const [EmptyState(title: 'مفيش طلبات هنا', hint: 'هتظهر هنا أول ما طالب تبعت إثبات الدفع، أو غيّر كلمة البحث.', mascot: 'robot')])
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: _subs.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => Tour.wrap(i == 0 ? 'req0' : null, _card(_subs[i])),
                        ),
                ),
        ),
      ]),
    );
  }

  Widget _card(Subscription s) {
    final st = s.json['student'] as Map?;
    final teacher = (s.json['teacher'] as Map?)?['fullName'];
    final sub = DateTime.tryParse('${s.json['submittedAt'] ?? ''}')?.toLocal();
    final reason = s.json['rejectReason'] as String?;
    return YaCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text('${st?['fullName'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Ya.ink))),
          switch (s.status) {
            'ACTIVE' => Pill.ok(s.statusLabel),
            'PENDING' => Pill.warn(s.statusLabel),
            'REJECTED' || 'CANCELLED' => Pill.bad(s.statusLabel),
            _ => Pill(s.statusLabel),
          },
        ]),
        if ((st?['studentCode'] ?? '').toString().isNotEmpty) Text('${st!['studentCode']}', textDirection: TextDirection.ltr, textAlign: TextAlign.right, style: const TextStyle(color: Ya.muted, fontSize: 13)),
        const SizedBox(height: 4),
        Text('${s.courseTitle} · ${s.typeLabel} · ${s.sessionsTotal} حصة · ${s.amount.toStringAsFixed(0)}', style: const TextStyle(color: Ya.muted, fontSize: 13.5, height: 1.7)),
        if (sub != null) Text('أُرسل ${fdt(sub)}', style: const TextStyle(color: Ya.muted, fontSize: 13)),
        if (teacher != null) Text('المعلم: $teacher', style: const TextStyle(color: Ya.muted, fontSize: 13)),
        if ((reason ?? '').isNotEmpty)
          Container(margin: const EdgeInsets.only(top: 8), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Ya.warnBg, borderRadius: BorderRadius.circular(14)), child: Text(reason!, style: const TextStyle(color: Ya.warn))),
        if (s.status == 'PENDING') ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(flex: 2, child: GradButton(label: 'موافقة', height: 46, onPressed: () => _approve(s))),
            const SizedBox(width: 8),
            Expanded(child: SoftButton(label: 'رفض', height: 46, onPressed: () => _reject(s))),
          ]),
        ],
      ]),
    );
  }
}
