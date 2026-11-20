import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/choice_pill.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../domain/gift_kind.dart';
import '../../domain/order.dart';
import '../../domain/order_input.dart';
import '../../domain/order_source.dart';

/// When the customer wants it, as the order form asks it.
enum _When {
  today('اليوم'),
  tomorrow('بكرا'),
  thisWeek('هالأسبوع'),
  noRush('مو مستعجل');

  const _When(this.label);
  final String label;

  /// End of the day they asked for: "today" means before midnight.
  DateTime? deadlineFrom(DateTime now) => switch (this) {
    today => DateTime(now.year, now.month, now.day, 23, 59),
    tomorrow => DateTime(now.year, now.month, now.day + 1, 23, 59),
    thisWeek => DateTime(now.year, now.month, now.day + 6, 23, 59),
    noRush => null,
  };
}

/// Adding an order straight from a chat, in a few taps.
///
/// Most orders now arrive as a WhatsApp or Instagram message from the bio
/// page, so this asks only what that first chat tells you; everything else
/// is filled in on the order later.
class QuickAddSheet extends StatefulWidget {
  const QuickAddSheet({super.key, required this.onSave});

  /// Saves the order; [build] turns a code into the draft.
  final Future<Order> Function(OrderDraft Function(String code) build) onSave;

  static Future<Order?> show(
    BuildContext context, {
    required Future<Order> Function(OrderDraft Function(String code) build)
    onSave,
  }) => showModalBottomSheet<Order>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => QuickAddSheet(onSave: onSave),
  );

  /// The kinds offered, most ordered first. «عيد الحبيبة» was a one-day
  /// offer and stays out of the picker (old orders keep it).
  static const kinds = [
    GiftKind.letter,
    GiftKind.birthday,
    GiftKind.sorry,
    GiftKind.wrapped,
    GiftKind.proposal,
    GiftKind.cup,
    GiftKind.wedding,
    GiftKind.engage,
    GiftKind.reveal,
    GiftKind.other,
  ];

  @override
  State<QuickAddSheet> createState() => _QuickAddSheetState();
}

class _QuickAddSheetState extends State<QuickAddSheet> {
  final _form = GlobalKey<FormState>();
  final _customer = TextEditingController();
  final _recipient = TextEditingController();
  final _contact = TextEditingController();
  final _notes = TextEditingController();

  GiftKind _kind = GiftKind.letter;
  OrderSource _source = OrderSource.whatsapp;
  int _package = 0;
  _When _when = _When.today;
  bool _saving = false;
  String? _error;

  List<({String name, int price})> get _packages =>
      OrderInput.packagesFor(_kind);

  @override
  void dispose() {
    _customer.dispose();
    _recipient.dispose();
    _contact.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _validateContact(String? v) {
    final text = v?.trim() ?? '';
    if (text.isEmpty) return null;
    final ok = _source == OrderSource.instagram
        ? OrderInput.instagram(text) != null
        : OrderInput.whatsapp(text) != null;
    if (ok) return null;
    return _source == OrderSource.instagram
        ? 'اسم الحساب بس، متل rasael.studio'
        : 'رقم مو مزبوط، متل 0933123456';
  }

  Future<void> _save() async {
    if (_saving || !(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final now = DateTime.now();
    final pkg = _packages[_package];
    final name = _customer.text.trim();
    final to = _recipient.text.trim();
    final contact = _contact.text.trim();
    final notes = _notes.text.trim();
    final ig = _source == OrderSource.instagram;

    try {
      final order = await widget.onSave(
        (code) => OrderDraft(
          code: code,
          kind: _kind,
          packageName: pkg.name,
          priceSyp: pkg.price,
          customerName: name,
          source: _source,
          customerWhatsapp: !ig && contact.isNotEmpty
              ? OrderInput.whatsapp(contact)
              : null,
          customerInstagram: ig && contact.isNotEmpty
              ? OrderInput.instagram(contact)
              : null,
          // The customer usually signs the page, so they're the sender.
          senderName: name,
          recipientName: to.isEmpty ? null : to,
          deadline: _when.deadlineFrom(now),
          notes: notes.isEmpty ? null : notes,
        ),
      );
      HapticFeedback.mediumImpact();
      if (mounted) Navigator.of(context).pop(order);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'ما انحفظ الطلب. تأكد من الإنترنت وجرّب كمان مرة.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final ig = _source == OrderSource.instagram;

    Widget label(String text, {String? hint}) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: text),
            if (hint != null)
              TextSpan(
                text: '  $hint',
                style: TextStyle(color: c.inkTertiary, fontWeight: FontWeight.w400),
              ),
          ],
        ),
        style: AppType.label.copyWith(color: c.inkSecondary),
      ),
    );

    Widget pills(List<Widget> children) => Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: children,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: insets),
      child: Form(
        key: _form,
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
              Text('طلب جديد', style: AppType.title.copyWith(color: c.ink)),
              Text(
                'من محادثة عالواتساب أو الإنستا. الباقي بتكمّله بعدين.',
                style: AppType.label.copyWith(color: c.inkTertiary),
              ),
              const SizedBox(height: AppSpacing.xl),

              label('من وين إجا؟'),
              pills([
                for (final s in const [OrderSource.whatsapp, OrderSource.instagram])
                  ChoicePill(
                    label: s.label,
                    selected: _source == s,
                    onTap: () => setState(() {
                      _source = s;
                      _contact.clear();
                    }),
                  ),
              ]),
              const SizedBox(height: AppSpacing.xl),

              TextFormField(
                controller: _customer,
                autofocus: true,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'اسم الزبون'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'لازم اسم' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _recipient,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'لمين الهدية؟',
                  hintText: 'إذا قال الاسم',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AnimatedSwitcher(
                duration: AppMotion.quick,
                child: TextFormField(
                  key: ValueKey(ig),
                  controller: _contact,
                  textDirection: TextDirection.ltr,
                  keyboardType: ig ? TextInputType.text : TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  decoration: InputDecoration(
                    labelText: ig ? 'حساب الإنستا' : 'رقم الواتساب',
                    hintText: ig ? '@account' : '0933 123 456',
                    hintTextDirection: TextDirection.ltr,
                  ),
                  validator: _validateContact,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              label('شو بدو؟'),
              pills([
                for (final k in QuickAddSheet.kinds)
                  ChoicePill(
                    label: k.label,
                    selected: _kind == k,
                    onTap: () => setState(() {
                      _kind = k;
                      _package = 0;
                    }),
                  ),
              ]),
              const SizedBox(height: AppSpacing.xl),

              label('الباقة'),
              pills([
                for (final (i, p) in _packages.indexed)
                  ChoicePill(
                    label: p.name,
                    trailing: Fmt.number(p.price),
                    selected: _package == i,
                    onTap: () => setState(() => _package = i),
                  ),
              ]),
              const SizedBox(height: AppSpacing.xl),

              label('أيمتى بدو ياها؟'),
              pills([
                for (final w in _When.values)
                  ChoicePill(
                    label: w.label,
                    selected: _when == w,
                    onTap: () => setState(() => _when = w),
                  ),
              ]),
              const SizedBox(height: AppSpacing.xl),

              TextFormField(
                controller: _notes,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات',
                  hintText: 'أي شي حكاه: الاسم الدلع، القصة، أغنية…',
                  alignLabelWithHint: true,
                ),
              ),

              AnimatedSize(
                duration: AppMotion.quick,
                alignment: AlignmentDirectional.topStart,
                child: _error == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: Text(
                          _error!,
                          style: AppType.label.copyWith(color: c.late),
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'ضيف الطلب · ${Fmt.syp(_packages[_package].price)}',
                busy: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
