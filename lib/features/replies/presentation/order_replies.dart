import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/motion.dart';
import '../../orders/domain/order.dart';
import '../domain/reply_template.dart';
import 'replies_cubit.dart';

/// The ready messages for this order at its current stage, already filled
/// with its names, price and link: copy, or send straight to WhatsApp.
class OrderReplies extends StatefulWidget {
  const OrderReplies({super.key, required this.order});

  final Order order;

  @override
  State<OrderReplies> createState() => _OrderRepliesState();
}

class _OrderRepliesState extends State<OrderReplies> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final all = context.watch<RepliesCubit>().state;
    if (all == null || all.isEmpty) return const SizedBox.shrink();

    final forStage = ReplyFill.forStage(all, widget.order.status);
    final first = forStage.where((t) => t.stage == widget.order.status);
    final shown = _showAll ? forStage : first.toList();
    final hidden = forStage.length - shown.length;

    return AnimatedSize(
      duration: AppMotion.move,
      curve: AppMotion.standard,
      alignment: AlignmentDirectional.topStart,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final t in shown) ...[
            _ReplyCard(template: t, order: widget.order),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (hidden > 0)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => setState(() => _showAll = true),
                child: Text(
                  shown.isEmpty ? 'شوف الردود ($hidden)' : 'ردود تانية ($hidden)',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ReplyCard extends StatelessWidget {
  const _ReplyCard({required this.template, required this.order});

  final ReplyTemplate template;
  final Order order;

  void _toast(BuildContext context, String text) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));

  Future<void> _copy(BuildContext context, FilledReply filled) async {
    await Clipboard.setData(ClipboardData(text: filled.text));
    HapticFeedback.selectionClick();
    if (context.mounted) _toast(context, 'انتسخ «${template.title}»');
  }

  /// WhatsApp takes the message in the link, so it opens ready to send.
  /// Instagram can't be pre-filled: copy, then open the chat to paste.
  Future<void> _send(BuildContext context, FilledReply filled) async {
    final wa = order.customerWhatsapp;
    final ig = order.customerInstagram;
    Uri uri;
    if (wa != null) {
      uri = Uri.parse(
        'https://wa.me/$wa?text=${Uri.encodeComponent(filled.text)}',
      );
    } else {
      await Clipboard.setData(ClipboardData(text: filled.text));
      uri = Uri.parse('https://ig.me/m/$ig');
      if (context.mounted) _toast(context, 'انتسخ، الصقه بالمحادثة');
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) _toast(context, 'ما قدرنا نفتح المحادثة');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final filled = ReplyFill.fill(template, order);
    final canSend =
        order.customerWhatsapp != null || order.customerInstagram != null;
    final viaWhatsapp = order.customerWhatsapp != null;

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.title,
                  style: AppType.label.copyWith(
                    color: c.inkSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  filled.text,
                  style: AppType.body.copyWith(color: c.ink, fontSize: 14),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!filled.complete) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'ناقص: ${filled.missing.map((f) => f.label).join('، ')}',
                    style: AppType.caption.copyWith(color: c.dueToday),
                  ),
                ],
              ],
            ),
          ),
          Container(height: 1, color: c.border),
          Row(
            children: [
              Expanded(
                child: _CardAction(
                  icon: Icons.copy_rounded,
                  label: 'انسخ',
                  onTap: () => _copy(context, filled),
                ),
              ),
              if (canSend) ...[
                Container(width: 1, height: 40, color: c.border),
                Expanded(
                  child: _CardAction(
                    icon: Icons.send_rounded,
                    label: viaWhatsapp ? 'ابعت بالواتساب' : 'افتح الإنستا',
                    // A reply with a gap isn't sent until the gap is filled.
                    onTap: filled.complete ? () => _send(context, filled) : null,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = onTap == null ? c.inkTertiary : c.accent;
    return Pressable(
      onTap: onTap,
      scale: 0.96,
      semanticLabel: label,
      child: SizedBox(
        height: 44,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              label,
              style: AppType.label.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
