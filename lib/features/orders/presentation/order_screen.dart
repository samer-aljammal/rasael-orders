import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/attention_badge.dart';
import '../../../core/widgets/choice_pill.dart';
import '../../../core/widgets/money.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/states.dart';
import '../../replies/presentation/order_replies.dart';
import '../domain/order.dart';
import '../domain/order_source.dart';
import '../domain/order_status.dart';
import 'orders_cubit.dart';
import 'widgets/pipeline_strip.dart';

/// Everything about one order, and the one action that moves it on.
///
/// Reads the order from the live list, so a change made on another device
/// (or by the button at the bottom) shows here immediately.
class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        if (state is! OrdersLoaded) {
          return Scaffold(
            appBar: AppBar(),
            body: state is OrdersError
                ? ErrorPanel(
                    message: state.message,
                    onRetry: context.read<OrdersCubit>().retry,
                  )
                : const Center(child: CircularProgressIndicator()),
          );
        }
        final order = state.orders.where((o) => o.id == orderId).firstOrNull;
        if (order == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyPanel(
              title: 'الطلب مو موجود',
              body: 'يمكن انمسح من جهاز تاني.',
            ),
          );
        }
        return _OrderView(order: order, now: state.now);
      },
    );
  }
}

class _OrderView extends StatelessWidget {
  const _OrderView({required this.order, required this.now});

  final Order order;
  final DateTime now;

  OrdersCubit _cubit(BuildContext context) => context.read<OrdersCubit>();

  void _toast(BuildContext context, String text) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _advance(BuildContext context) async {
    final cubit = _cubit(context);
    PaymentMethod? paidWith;
    if (order.status.next == OrderStatus.paid) {
      paidWith = await _PaymentSheet.show(context);
      if (paidWith == null) return;
    }
    await cubit.moveForward(order, paidWith: paidWith);
    HapticFeedback.mediumImpact();
  }

  Future<void> _copy(BuildContext context, String text, String what) async {
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.selectionClick();
    if (context.mounted) _toast(context, 'انتسخ $what');
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) _toast(context, 'ما قدرنا نفتح الرابط');
  }

  Future<void> _editText(
    BuildContext context, {
    required String title,
    required String? initial,
    required Future<void> Function(String?) save,
    String? hint,
    bool ltr = false,
    bool multiline = false,
  }) async {
    final controller = TextEditingController(text: initial ?? '');
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: multiline ? 3 : 1,
          maxLines: multiline ? 8 : 1,
          textDirection: ltr ? TextDirection.ltr : null,
          keyboardType: ltr ? TextInputType.url : TextInputType.multiline,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('احفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) await save(value);
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final cubit = _cubit(context);
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الطلب؟'),
        content: Text(
          'بيضل بالسجل تحت «ملغى» وما بينحسب بالمدخول. '
          'فيك ترجّعو بعدين.',
          style: AppType.body.copyWith(color: context.colors.inkSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('لا، خليه'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: context.colors.late),
            child: const Text('إلغاء الطلب'),
          ),
        ],
      ),
    );
    if (yes ?? false) await cubit.cancel(order);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final attention = order.attentionAt(now);
    final action = order.status.nextAction;
    final back = order.status.previous;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onLongPress: () => _copy(context, order.code, 'الكود'),
          child: Text(
            Fmt.ltr(order.code),
            style: AppType.numeric.copyWith(
              color: c.inkSecondary,
              fontSize: 15,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'خيارات',
            icon: Icon(Icons.more_horiz_rounded, color: c.inkSecondary),
            position: PopupMenuPosition.under,
            onSelected: (v) => switch (v) {
              'copy' => _copy(context, order.code, 'الكود'),
              'back' => _cubit(context).moveBack(order),
              'cancel' => _confirmCancel(context),
              _ => null,
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'copy', child: Text('انسخ الكود')),
              if (back != null)
                PopupMenuItem(
                  value: 'back',
                  child: Text(
                    order.status == OrderStatus.cancelled
                        ? 'رجّع الطلب'
                        : 'رجّع خطوة لـ «${back.label}»',
                  ),
                ),
              if (order.status.isOpen)
                PopupMenuItem(
                  value: 'cancel',
                  child: Text(
                    'إلغاء الطلب',
                    style: TextStyle(color: c.late),
                  ),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: action == null
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screen,
                  AppSpacing.md,
                  AppSpacing.screen,
                  AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: c.background,
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: PrimaryButton(
                  label: action,
                  onPressed: () => _advance(context),
                ),
              ),
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screen,
              AppSpacing.sm,
              AppSpacing.screen,
              AppSpacing.xxxl,
            ),
            children: [
              // -- Who and what ----------------------------------------------
              Reveal(
                child: Row(
                  children: [
                    Text(
                      order.kind.label,
                      style: AppType.label.copyWith(color: c.inkTertiary),
                    ),
                    const Spacer(),
                    if (attention != null) AttentionBadge(attention),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Reveal(
                index: 1,
                child: Text(
                  order.headline,
                  style: AppType.headline.copyWith(color: c.ink),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Reveal(
                index: 2,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Money(
                      order.priceSyp,
                      style: AppType.title.copyWith(
                        color: c.ink,
                        fontFeatures: AppType.numeric.fontFeatures,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      order.packageName,
                      style: AppType.label.copyWith(color: c.inkSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Reveal(index: 3, child: PipelineStrip(current: order.status)),
              const SizedBox(height: AppSpacing.sm),
              Reveal(
                index: 3,
                child: Text(
                  order.status.hint,
                  style: AppType.caption.copyWith(color: c.inkTertiary),
                ),
              ),

              // -- The message to send now -----------------------------------
              const _Section('ردود جاهزة'),
              OrderReplies(order: order),

              // -- Customer ------------------------------------------------
              const _Section('الزبون'),
              _Row(label: 'الاسم', value: order.customerName),
              if (order.customerWhatsapp != null)
                _Row(
                  label: 'واتساب',
                  value: Fmt.ltr('+${order.customerWhatsapp}'),
                  numeric: true,
                  onTap: () => _open(
                    context,
                    Uri.parse('https://wa.me/${order.customerWhatsapp}'),
                  ),
                  onLongPress: () =>
                      _copy(context, order.customerWhatsapp!, 'الرقم'),
                  action: Icons.chat_bubble_outline_rounded,
                  actionLabel: 'افتح المحادثة',
                ),
              if (order.customerInstagram != null)
                _Row(
                  label: 'إنستا',
                  value: Fmt.ltr('@${order.customerInstagram}'),
                  onTap: () => _open(
                    context,
                    Uri.parse('https://ig.me/m/${order.customerInstagram}'),
                  ),
                  onLongPress: () =>
                      _copy(context, order.customerInstagram!, 'الحساب'),
                  action: Icons.chat_bubble_outline_rounded,
                  actionLabel: 'افتح المحادثة',
                ),
              if (order.source != null)
                _Row(label: 'إجا من', value: order.source!.label),
              if (order.deadline != null)
                _Row(
                  label: 'بدو ياها',
                  value:
                      '${Fmt.dayMonth(order.deadline!)}، ${Fmt.time(order.deadline!)}',
                ),

              // -- The page ------------------------------------------------
              const _Section('الصفحة'),
              if (order.pageUrl == null)
                _Row(
                  label: 'الرابط',
                  value: 'ضيف رابط الصفحة',
                  muted: true,
                  action: Icons.add_rounded,
                  actionLabel: 'ضيف الرابط',
                  onTap: () => _editText(
                    context,
                    title: 'رابط الصفحة',
                    initial: null,
                    hint: 'https://rasaelstudio.github.io/…',
                    ltr: true,
                    save: (v) => _cubit(context).setPageUrl(order, v),
                  ),
                )
              else
                _Row(
                  label: 'الرابط',
                  value: Fmt.ltr(
                    order.pageUrl!.replaceFirst(RegExp('^https?://'), ''),
                  ),
                  numeric: true,
                  onTap: () => _open(context, Uri.parse(order.pageUrl!)),
                  onLongPress: () => _copy(context, order.pageUrl!, 'الرابط'),
                  action: Icons.copy_rounded,
                  actionLabel: 'انسخ الرابط',
                  onAction: () => _copy(context, order.pageUrl!, 'الرابط'),
                ),
              if (order.wantsMusic || order.hasPhotos)
                _Row(
                  label: 'مع',
                  value: [
                    if (order.wantsMusic) 'موسيقى',
                    if (order.hasPhotos) 'صور',
                  ].join(' و'),
                ),

              // -- What they asked for ---------------------------------------
              if (order.details.isNotEmpty) ...[
                const _Section('التفاصيل'),
                for (final d in order.details)
                  _Row(label: d.label, value: d.value, stacked: true),
              ],

              const _Section('ملاحظات'),
              _Row(
                label: '',
                value: order.notes ?? 'ضيف ملاحظة',
                muted: order.notes == null,
                stacked: true,
                action: Icons.edit_outlined,
                actionLabel: 'عدّل الملاحظات',
                onTap: () => _editText(
                  context,
                  title: 'ملاحظات',
                  initial: order.notes,
                  multiline: true,
                  save: (v) => _cubit(context).setNotes(order, v),
                ),
              ),

              // -- When things happened --------------------------------------
              const _Section('المراحل'),
              _Timeline(order: order),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: AppSpacing.section,
      bottom: AppSpacing.xs,
    ),
    child: Text(
      title,
      style: AppType.section.copyWith(color: context.colors.inkSecondary),
    ),
  );
}

/// A ledger row: label on the start side, value after it, an optional
/// action at the end. [stacked] puts long values under their label.
class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.onTap,
    this.onLongPress,
    this.action,
    this.actionLabel,
    this.onAction,
    this.numeric = false,
    this.muted = false,
    this.stacked = false,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final IconData? action;
  final String? actionLabel;

  /// Defaults to [onTap].
  final VoidCallback? onAction;
  final bool numeric;
  final bool muted;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final valueStyle = (numeric ? AppType.numeric : AppType.body).copyWith(
      color: muted ? c.inkTertiary : c.ink,
    );
    final labelText = Text(
      label,
      style: AppType.label.copyWith(color: c.inkTertiary),
    );
    final valueText = Text(value, style: valueStyle);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSizes.minTouchTarget + 4),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: stacked
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (label.isNotEmpty) labelText,
                        valueText,
                      ],
                    )
                  : Row(
                      children: [
                        SizedBox(width: 84, child: labelText),
                        Expanded(child: valueText),
                      ],
                    ),
            ),
            if (action != null)
              IconButton(
                tooltip: actionLabel,
                onPressed: onAction ?? onTap,
                icon: Icon(action, size: 20, color: c.inkSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

/// When each stage happened, only for the stages the order has reached.
class _Timeline extends StatelessWidget {
  const _Timeline({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final reached = OrderStatus.pipeline.indexOf(order.status);
    bool at(OrderStatus s) => reached >= OrderStatus.pipeline.indexOf(s);

    final steps = <(String, DateTime?, String?)>[
      ('وصل الطلب', order.createdAt, null),
      if (at(OrderStatus.previewSent))
        ('انبعتت المعاينة', order.previewSentAt, null),
      if (at(OrderStatus.paid))
        ('وصل الدفع', order.paidAt, order.paymentMethod?.label),
      if (at(OrderStatus.delivered)) ('انسلّم الرابط', order.deliveredAt, null),
      if (order.status == OrderStatus.cancelled)
        ('انلغى', order.updatedAt, null),
    ];

    return Column(
      children: [
        for (final (i, (label, time, extra)) in steps.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 20,
                  child: Column(
                    children: [
                      Container(
                        width: 2,
                        height: 14,
                        color: i == 0 ? Colors.transparent : c.borderStrong,
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == steps.length - 1 ? c.accent : c.ink,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          width: 2,
                          color: i == steps.length - 1
                              ? Colors.transparent
                              : c.borderStrong,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            extra == null ? label : '$label · $extra',
                            style: AppType.body.copyWith(color: c.ink),
                          ),
                        ),
                        Text(
                          time == null
                              ? '—'
                              : '${Fmt.dayMonth(time)}، ${Fmt.time(time)}',
                          style: AppType.caption.copyWith(
                            color: c.inkTertiary,
                            fontFeatures: AppType.numeric.fontFeatures,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// "How did they pay?", asked once, at the moment the money arrives.
class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet();

  static Future<PaymentMethod?> show(BuildContext context) =>
      showModalBottomSheet<PaymentMethod>(
        context: context,
        builder: (_) => const _PaymentSheet(),
      );

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  // Almost every order so far came in on Sham Cash.
  PaymentMethod _method = PaymentMethod.shamCash;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screen,
          0,
          AppSpacing.screen,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('كيف دفع؟', style: AppType.title.copyWith(color: c.ink)),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final m in PaymentMethod.values)
                  ChoicePill(
                    label: m.label,
                    selected: _method == m,
                    onTap: () => setState(() => _method = m),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(
              label: 'وصل الدفع',
              onPressed: () => Navigator.pop(context, _method),
            ),
          ],
        ),
      ),
    );
  }
}
