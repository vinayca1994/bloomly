import 'package:flutter/material.dart';

import 'bloom_tokens.dart';

export 'bloom_tokens.dart';

class BloomlyType {
  static const ui = 'PlusJakartaSans';
  static const displayFamily = 'BricolageGrotesque';

  static const TextStyle label = TextStyle(
    inherit: false,
    fontFamily: ui,
    fontWeight: FontWeight.w800,
    fontVariations: [FontVariation.weight(800)],
    fontSize: 16,
    height: 1.25,
  );

  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w700,
    Color? color,
    double height = 1.15,
  }) {
    return TextStyle(
      fontFamily: displayFamily,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation.weight(weight.value.toDouble())],
      color: color,
      height: height,
      letterSpacing: size >= 24 ? -0.4 : -0.2,
    );
  }

  static TextStyle uiText(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double height = 1.35,
  }) {
    return TextStyle(
      fontFamily: ui,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation.weight(weight.value.toDouble())],
      color: color,
      height: height,
    );
  }
}

class BloomlyDecor {
  static BoxDecoration card(
    BloomTokens tokens, {
    Color? color,
    double radius = BloomTokens.radiusLg,
    bool border = true,
  }) {
    return BoxDecoration(
      color: color ?? tokens.surface,
      borderRadius: BorderRadius.circular(radius),
      border: border ? Border.all(color: tokens.border) : null,
      boxShadow: tokens.cardShadow,
    );
  }
}

class BloomlyTheme {
  static ThemeData light() => _build(BloomTokens.light);

  static ThemeData dark() => _build(BloomTokens.dark);

  static ThemeData _build(BloomTokens tokens) {
    final scheme = ColorScheme.fromSeed(
      seedColor: tokens.primary,
      brightness: tokens.brightness,
    ).copyWith(
      primary: tokens.primary,
      onPrimary: tokens.onPrimary,
      secondary: tokens.secondary,
      onSecondary: tokens.onSecondary,
      surface: tokens.surface,
      onSurface: tokens.text,
      error: tokens.danger,
      onError: tokens.onPrimary,
      outline: tokens.border,
      outlineVariant: tokens.border,
    );
    final radius = BorderRadius.circular(999);
    final label = BloomlyType.label.copyWith(color: tokens.onPrimary);
    final text = _textTheme(tokens);
    return ThemeData(
      useMaterial3: true,
      brightness: tokens.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: tokens.canvas,
      fontFamily: BloomlyType.ui,
      textTheme: text,
      primaryTextTheme: text,
      extensions: [tokens],
      splashColor: tokens.primary.withValues(alpha: 0.08),
      highlightColor: tokens.primary.withValues(alpha: 0.06),
      focusColor: tokens.borderFocus,
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.canvas,
        foregroundColor: tokens.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: BloomlyType.display(20, height: 1.3, color: tokens.text),
        iconTheme: IconThemeData(color: tokens.text),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.surface,
        elevation: 0,
        height: 76,
        indicatorColor: tokens.secondary,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? tokens.link : tokens.textSecondary,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return BloomlyType.uiText(
            11,
            weight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? tokens.link : tokens.textSecondary,
            height: 1.2,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.onPrimary,
          disabledBackgroundColor: tokens.sunken,
          disabledForegroundColor: tokens.textDisabled,
          minimumSize: const Size(48, 56),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.text,
          minimumSize: const Size(48, 48),
          side: BorderSide(color: tokens.borderStrong, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: BloomlyType.label.copyWith(color: tokens.text, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: tokens.link,
          minimumSize: const Size(48, 48),
          textStyle: BloomlyType.label.copyWith(color: tokens.link, fontSize: 14),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: tokens.text,
          minimumSize: const Size(48, 48),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: tokens.surface,
        selectedColor: tokens.secondary,
        labelStyle: BloomlyType.uiText(
          13,
          weight: FontWeight.w800,
          color: tokens.text,
        ),
        secondaryLabelStyle: BloomlyType.uiText(
          13,
          weight: FontWeight.w800,
          color: tokens.onSecondary,
        ),
        side: BorderSide(color: tokens.border),
        shape: RoundedRectangleBorder(borderRadius: radius),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      cardTheme: CardThemeData(
        color: tokens.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BloomTokens.radiusLg),
          side: BorderSide(color: tokens.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: tokens.border, thickness: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return bloomWhite;
          return tokens.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return tokens.primary;
          return tokens.borderStrong;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: tokens.primary),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokens.inverse,
        contentTextStyle: BloomlyType.uiText(
          14,
          weight: FontWeight.w600,
          color: tokens.textInverse,
        ),
        actionTextColor: tokens.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BloomTokens.radiusMd),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: tokens.raised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BloomTokens.radiusXl),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: tokens.raised,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: tokens.text,
        textColor: tokens.text,
        minVerticalPadding: 12,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        labelStyle: BloomlyType.uiText(13, weight: FontWeight.w800, color: tokens.textSecondary),
        hintStyle: BloomlyType.uiText(16, color: tokens.textSecondary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: _fieldBorder(tokens.borderStrong, 1.5),
        enabledBorder: _fieldBorder(tokens.borderStrong, 1.5),
        focusedBorder: _fieldBorder(tokens.borderFocus, 2),
        errorBorder: _fieldBorder(tokens.danger, 2),
        focusedErrorBorder: _fieldBorder(tokens.danger, 2),
      ),
    );
  }

  static OutlineInputBorder _fieldBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(BloomTokens.radiusMd),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static TextTheme _textTheme(BloomTokens tokens) {
    TextStyle display(double size, double height, [FontWeight weight = FontWeight.w700]) {
      return BloomlyType.display(size, height: height, weight: weight, color: tokens.text);
    }

    TextStyle ui(double size, double height, FontWeight weight) {
      return BloomlyType.uiText(size, height: height, weight: weight, color: tokens.text);
    }

    return TextTheme(
      displayLarge: display(40, 44 / 40),
      displayMedium: display(32, 36 / 32),
      displaySmall: display(28, 32 / 28),
      headlineMedium: display(24, 28 / 24),
      headlineSmall: display(22, 28 / 22),
      titleLarge: display(20, 26 / 20, FontWeight.w600),
      titleMedium: display(16, 22 / 16, FontWeight.w600),
      titleSmall: ui(14, 18 / 14, FontWeight.w800),
      bodyLarge: ui(16, 24 / 16, FontWeight.w400),
      bodyMedium: ui(14, 20 / 14, FontWeight.w400),
      bodySmall: ui(13, 18 / 13, FontWeight.w400),
      labelLarge: ui(16, 20 / 16, FontWeight.w800),
      labelMedium: ui(13, 16 / 13, FontWeight.w800),
      labelSmall: ui(11, 14 / 11, FontWeight.w600),
    );
  }
}
