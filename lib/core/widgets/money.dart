import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/formatters.dart';

/// A price as two pieces: the figure, then a quieter «ل.س».
///
/// Separate widgets in a row rather than one string, so the figure always
/// sits on the reading-start side in RTL, whatever the bidi algorithm does
/// with a digit-first run.
class Money extends StatelessWidget {
  const Money(this.syp, {super.key, this.style});

  final int syp;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = style ?? AppType.numeric.copyWith(color: c.ink);
    return Semantics(
      label: Fmt.syp(syp),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(Fmt.number(syp), style: base),
          const SizedBox(width: 3),
          Text(
            'ل.س',
            style: base.copyWith(
              fontSize: (base.fontSize ?? 15) * 0.78,
              fontWeight: FontWeight.w500,
              color: c.inkTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
