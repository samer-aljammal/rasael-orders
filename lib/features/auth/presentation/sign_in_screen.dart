import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/money.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/primary_button.dart';
import '../../orders/data/demo_seed.dart';
import '../../orders/domain/order.dart';
import 'auth_cubit.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= AppSizes.wideBreakpoint;
          // Wordmark pinned to the top; the form sits in the lower part of
          // the screen, where a thumb reaches it. Scrolls when the keyboard
          // or a large text size needs the room.
          final form = SafeArea(
            child: LayoutBuilder(
              builder: (context, area) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screen,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: area.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        const Reveal(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Wordmark(size: 22, product: 'الطلبات'),
                          ),
                        ),
                        const Spacer(flex: 2),
                        const SizedBox(height: AppSpacing.xxxl),
                        Align(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: const _SignInForm(),
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: AppSpacing.xxxl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          if (!wide) return form;
          return Row(
            children: [
              Expanded(flex: 5, child: form),
              Expanded(
                flex: 6,
                child: ColoredBox(color: c.surfaceAlt, child: const _SlipDesk()),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SignInForm extends StatefulWidget {
  const _SignInForm();

  @override
  State<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<_SignInForm> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    context.read<AuthCubit>().signIn(_email.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = context.watch<AuthCubit>();
    final state = auth.state;
    final backend = auth.backendAvailable;

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Reveal(
            index: 1,
            child: Text(
              'دفتر الطلبات',
              style: AppType.headline.copyWith(color: c.ink, fontSize: 32),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Reveal(
            index: 2,
            child: Text(
              'كل طلب، من أول رسالة عالواتساب لحد ما يوصل الرابط.',
              style: AppType.body.copyWith(color: c.inkSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          if (backend) ...[
            Reveal(
              index: 3,
              child: TextFormField(
                controller: _email,
                enabled: !state.busy,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(labelText: 'الإيميل'),
                onChanged: (_) => auth.clearError(),
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'اكتب إيميل صحيح'
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Reveal(
              index: 4,
              child: TextFormField(
                controller: _password,
                focusNode: _passwordFocus,
                enabled: !state.busy,
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: 'كلمة السر',
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'أظهر كلمة السر' : 'خبّي كلمة السر',
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                    ),
                  ),
                ),
                onChanged: (_) => auth.clearError(),
                onFieldSubmitted: (_) => _submit(),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'اكتب كلمة السر' : null,
              ),
            ),
            _ErrorLine(message: state.error),
            const SizedBox(height: AppSpacing.lg),
            Reveal(
              index: 5,
              child: PrimaryButton(
                label: 'دخول',
                busy: state.busy,
                onPressed: _submit,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Reveal(
              index: 6,
              child: _DemoLink(onTap: state.busy ? null : auth.enterDemo),
            ),
          ] else ...[
            Reveal(
              index: 3,
              child: Text(
                'هالنسخة للعرض، ما فيها خادم. فيك تجرّب كل شي على طلبات وهمية: '
                'الأسماء والأرقام كلها مخترعة.',
                style: AppType.body.copyWith(color: c.inkSecondary),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Reveal(
              index: 4,
              child: PrimaryButton(
                label: 'افتح النسخة التجريبية',
                onPressed: auth.enterDemo,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Grows open under the button rather than popping in, so the form doesn't
/// jump when an error appears or clears.
class _ErrorLine extends StatelessWidget {
  const _ErrorLine({this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AnimatedSize(
      duration: AppMotion.quick,
      curve: AppMotion.standard,
      alignment: AlignmentDirectional.topStart,
      child: message == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Semantics(
                liveRegion: true,
                child: Text(
                  message!,
                  style: AppType.label.copyWith(color: c.late),
                ),
              ),
            ),
    );
  }
}

class _DemoLink extends StatelessWidget {
  const _DemoLink({this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'جرّب بدون حساب',
                    style: AppType.subtitle.copyWith(color: c.ink),
                  ),
                  Text(
                    'طلبات وهمية، فيك تحرّكها وتلعب فيها.',
                    style: AppType.caption.copyWith(color: c.inkTertiary),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_back_rounded, size: 20, color: c.inkSecondary),
          ],
        ),
      ),
    );
  }
}

/// Wide layouts: a few order slips lying on the desk, drawn from the demo
/// orders. Shows what the product is about before anyone signs in.
class _SlipDesk extends StatelessWidget {
  const _SlipDesk();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final all = DemoSeed.orders(now);
    final slips = [all[1], all[6], all[0]];
    const placements = [
      (Offset(-80, -170), -4.0),
      (Offset(70, -2), 3.0),
      (Offset(-36, 166), -1.5),
    ];

    return ExcludeSemantics(
      child: Center(
        child: SizedBox(
          width: 440,
          height: 600,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < slips.length; i++)
                Reveal(
                  index: 3 + i * 2,
                  offset: 26,
                  child: Transform.translate(
                    offset: placements[i].$1,
                    child: Transform.rotate(
                      angle: placements[i].$2 * math.pi / 180,
                      child: _Slip(order: slips[i], now: now),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slip extends StatelessWidget {
  const _Slip({required this.order, required this.now});

  final Order order;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      width: 280,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: c.border),
        // Paper on a desk genuinely floats; the one place a shadow belongs.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'طلب جديد',
                style: AppType.caption.copyWith(color: c.inkTertiary),
              ),
              const Spacer(),
              Text(
                Fmt.ltr(order.code),
                style: AppType.numeric.copyWith(
                  fontSize: 12,
                  color: c.inkTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(order.headline, style: AppType.title.copyWith(color: c.ink)),
          Text(
            order.kind.label,
            style: AppType.label.copyWith(color: c.inkSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(height: 1, color: c.border),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                order.packageName,
                style: AppType.caption.copyWith(color: c.inkTertiary),
              ),
              const Spacer(),
              Money(order.priceSyp),
            ],
          ),
        ],
      ),
    );
  }
}
