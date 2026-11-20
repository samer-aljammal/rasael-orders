import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/states.dart';
import '../../orders/domain/order_status.dart';
import '../domain/reply_template.dart';
import 'replies_cubit.dart';

/// Every saved reply, grouped by the stage it's for.
class RepliesScreen extends StatelessWidget {
  const RepliesScreen({super.key});

  /// Stage order for the groups; general replies come last.
  static const _groups = <OrderStatus?>[...OrderStatus.pipeline, null];

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final all = context.watch<RepliesCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الردود الجاهزة'),
        titleSpacing: 0,
        actions: [
          TextButton.icon(
            onPressed: () => ReplyEditor.show(context),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('رد جديد'),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
          child: all == null
              ? const Center(child: CircularProgressIndicator())
              : all.isEmpty
              ? const EmptyPanel(
                  title: 'ما في ردود',
                  body: 'ضيف رد بتبعتو كتير، وبيطلع عند كل طلب بمرحلتو.',
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        AppSpacing.xs,
                        AppSpacing.screen,
                        AppSpacing.sm,
                      ),
                      child: Text(
                        'كل رد بيطلع بصفحة الطلب لما يكون بمرحلتو، '
                        'والفراغات متل {الزبون} و{السعر} بتتعبّى لحالها.',
                        style: AppType.label.copyWith(color: c.inkTertiary),
                      ),
                    ),
                    for (final stage in _groups)
                      ..._group(context, stage, all),
                  ],
                ),
        ),
      ),
    );
  }

  List<Widget> _group(
    BuildContext context,
    OrderStatus? stage,
    List<ReplyTemplate> all,
  ) {
    final c = context.colors;
    final items = all.where((t) => t.stage == stage).toList()
      ..sort((a, b) => a.sort.compareTo(b.sort));
    if (items.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          AppSpacing.xl,
          AppSpacing.screen,
          AppSpacing.xs,
        ),
        child: Text(
          stage == null ? 'بأي مرحلة' : stage.label,
          style: AppType.section.copyWith(color: c.inkSecondary),
        ),
      ),
      for (final t in items)
        InkWell(
          onTap: () => ReplyEditor.show(context, existing: t),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screen,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title, style: AppType.subtitle.copyWith(color: c.ink)),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  t.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.label.copyWith(color: c.inkTertiary),
                ),
              ],
            ),
          ),
        ),
    ];
  }
}

/// Adding or editing a reply. The blanks are inserted with a tap, at the
/// cursor, so nobody has to type braces on a phone keyboard.
class ReplyEditor extends StatefulWidget {
  const ReplyEditor({super.key, this.existing});

  final ReplyTemplate? existing;

  static Future<void> show(BuildContext context, {ReplyTemplate? existing}) {
    final cubit = context.read<RepliesCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: ReplyEditor(existing: existing),
      ),
    );
  }

  @override
  State<ReplyEditor> createState() => _ReplyEditorState();
}

class _ReplyEditorState extends State<ReplyEditor> {
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _body = TextEditingController(text: widget.existing?.body);
  late OrderStatus? _stage = widget.existing?.stage;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  void _insert(ReplyField f) {
    final sel = _body.selection;
    final text = _body.text;
    final at = sel.isValid ? sel.start : text.length;
    final end = sel.isValid ? sel.end : text.length;
    _body.value = TextEditingValue(
      text: text.replaceRange(at, end, f.token),
      selection: TextSelection.collapsed(offset: at + f.token.length),
    );
  }

  bool get _valid =>
      _title.text.trim().isNotEmpty && _body.text.trim().isNotEmpty;

  Future<void> _save() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    final cubit = context.read<RepliesCubit>();
    final e = widget.existing;
    if (e == null) {
      await cubit.add(_title.text, _body.text, _stage);
    } else {
      await cubit.save(
        e.copyWith(
          title: _title.text.trim(),
          body: _body.text.trim(),
          stage: () => _stage,
        ),
      );
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final cubit = context.read<RepliesCubit>();
    final nav = Navigator.of(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تمسح هالرد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لا'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.colors.late),
            child: const Text('امسح'),
          ),
        ],
      ),
    );
    if (yes ?? false) {
      await cubit.delete(widget.existing!);
      nav.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.existing == null ? 'رد جديد' : 'عدّل الرد',
                    style: AppType.title.copyWith(color: c.ink),
                  ),
                ),
                if (widget.existing != null)
                  IconButton(
                    tooltip: 'امسح الرد',
                    onPressed: _delete,
                    icon: Icon(Icons.delete_outline_rounded, color: c.late),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _title,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'اسم الرد',
                hintText: 'متل: الرابط بعد الدفع',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'بيطلع بمرحلة',
              style: AppType.label.copyWith(color: c.inkSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final s in <OrderStatus?>[null, ...OrderStatus.pipeline])
                  ChoicePill(
                    label: s?.label ?? 'أي مرحلة',
                    selected: _stage == s,
                    onTap: () => setState(() => _stage = s),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _body,
              onChanged: (_) => setState(() {}),
              minLines: 6,
              maxLines: 14,
              decoration: const InputDecoration(
                labelText: 'نص الرد',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'كبسة بتحط فراغ بيتعبّى من الطلب:',
              style: AppType.caption.copyWith(color: c.inkTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final f in ReplyField.values)
                  ActionChip(
                    label: Text(f.label),
                    onPressed: () => _insert(f),
                    backgroundColor: c.surfaceAlt,
                    side: BorderSide.none,
                    labelStyle: AppType.caption.copyWith(color: c.ink),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'احفظ',
              busy: _saving,
              onPressed: _valid ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}
