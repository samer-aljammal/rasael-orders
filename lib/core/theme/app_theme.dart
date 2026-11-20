import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Material themes built from the Rasael tokens.
///
/// Component themes live here so feature screens never restyle framework
/// widgets locally. Surfaces are flat with hairlines; shadows only on
/// things that float.
abstract final class AppTheme {
  static ThemeData light() => _build(RasaelColors.light, Brightness.light);
  static ThemeData dark() => _build(RasaelColors.dark, Brightness.dark);

  static ThemeData _build(RasaelColors c, Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      secondary: c.surfaceAlt,
      onSecondary: c.ink,
      error: c.late,
      onError: isLight ? Colors.white : c.background,
      surface: c.surface,
      onSurface: c.ink,
      onSurfaceVariant: c.inkSecondary,
      outline: c.border,
      outlineVariant: c.border,
      surfaceContainerHighest: c.surfaceAlt,
      surfaceContainerLow: c.surface,
      inverseSurface: c.surfaceInverse,
      onInverseSurface: c.inkInverse,
      shadow: Colors.black,
      scrim: c.scrim,
    );

    TextStyle t(TextStyle s, Color color) => s.copyWith(color: color);

    final textTheme = TextTheme(
      displayLarge: t(AppType.display, c.ink),
      headlineMedium: t(AppType.headline, c.ink),
      titleLarge: t(AppType.title, c.ink),
      titleMedium: t(AppType.subtitle, c.ink),
      bodyLarge: t(AppType.body, c.ink),
      bodyMedium: t(AppType.body, c.ink),
      bodySmall: t(AppType.caption, c.inkSecondary),
      labelLarge: t(AppType.subtitle, c.ink),
      labelMedium: t(AppType.label, c.inkSecondary),
      labelSmall: t(AppType.caption, c.inkTertiary),
    );

    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: c.border),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppFonts.text,
      colorScheme: scheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      dividerColor: c.border,
      extensions: [c],
      // No ripples: the expanding ink splash is the most recognisable stock
      // Material tell. Rows get a quiet highlight; cards get a spring press.
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: c.ink.withValues(alpha: isLight ? 0.05 : 0.07),
      hoverColor: c.ink.withValues(alpha: 0.03),
      focusColor: c.accent.withValues(alpha: 0.12),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionColor: c.accent.withValues(alpha: 0.22),
        selectionHandleColor: c.accent,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: t(AppType.title, c.ink),
        systemOverlayStyle:
            (isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light)
                .copyWith(statusBarColor: Colors.transparent),
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1, space: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.accent,
          foregroundColor: c.onAccent,
          disabledBackgroundColor: c.surfaceAlt,
          disabledForegroundColor: c.inkTertiary,
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppType.subtitle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          side: BorderSide(color: c.borderStrong),
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: AppType.subtitle,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          minimumSize: const Size(
            AppSizes.minTouchTarget,
            AppSizes.minTouchTarget,
          ),
          textStyle: AppType.label.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 15,
        ),
        hintStyle: t(AppType.body, c.inkTertiary),
        labelStyle: t(AppType.body, c.inkSecondary),
        floatingLabelStyle: t(AppType.label, c.accent),
        errorStyle: t(AppType.caption, c.late),
        prefixIconColor: c.inkTertiary,
        suffixIconColor: c.inkTertiary,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        errorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: c.late)),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: c.late, width: 1.5),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: c.borderStrong,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        titleTextStyle: t(AppType.title, c.ink),
        contentTextStyle: t(AppType.body, c.inkSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceInverse,
        contentTextStyle: t(AppType.label, c.inkInverse),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.surfaceAlt,
        circularTrackColor: c.surfaceAlt,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.surfaceInverse,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        textStyle: t(AppType.caption, c.inkInverse),
      ),
      iconTheme: IconThemeData(color: c.inkSecondary, size: 22),
    );
  }
}
