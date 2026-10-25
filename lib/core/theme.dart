import 'package:flutter/material.dart';

class BloomlyColors {
  /// Gold from the line under the bloom wordmark. Fills use this.
  static const gold = Color(0xFFF0C14A);

  /// Deeper amber for icons, links, and selected labels on white.
  static const amber = Color(0xFF8A5A00);

  static const green = gold;
  static const greenDark = amber;
  static const marigold = Color(0xFFE4572E);
  static const paper = Color(0xFFF7F4EC);
  static const background = paper;
  static const ink = Color(0xFF172026);
  static const muted = Color(0xFF5E6B73);
  static const line = Color(0xFFE4DDD0);
  static const canvas = Color(0xFFF7F4EC);
  static const danger = Color(0xFFB42318);
  static const card = Color(0xFFFFFFFF);
  static const peach = Color(0xFFFDE7EF);
  static const leafWash = Color(0xFFFFF6D8);
  static const fruitWash = Color(0xFFFFF0E8);
}

class BloomlyType {
  /// Plus Jakarta is a variable font. A weight on its own does not select a
  /// face on web, so labels that must stay bold name the family themselves.
  static const TextStyle label = TextStyle(
    inherit: false,
    fontFamily: 'PlusJakartaSans',
    fontWeight: FontWeight.w800,
    fontVariations: [FontVariation.weight(700)],
    fontSize: 16,
    height: 1.2,
    color: BloomlyColors.ink,
  );

  static TextStyle display(
    double size, {
    FontWeight weight = FontWeight.w600,
    Color? color,
    double height = 1.05,
  }) {
    return TextStyle(
      fontFamily: 'Fraunces',
      fontSize: size,
      fontWeight: weight,
      color: color ?? BloomlyColors.ink,
      height: height,
    );
  }
}

class BloomlyDecor {
  static List<BoxShadow> get shadow => [
    BoxShadow(
      color: BloomlyColors.ink.withValues(alpha: 0.06),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];

  static BoxDecoration card({Color? color, double radius = 20}) {
    return BoxDecoration(
      color: color ?? BloomlyColors.card,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadow,
    );
  }
}

class BloomlyTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: BloomlyColors.green,
      primary: BloomlyColors.green,
      surface: BloomlyColors.paper,
    );
    final radius = BorderRadius.circular(999);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: BloomlyColors.paper,
      appBarTheme: AppBarTheme(
        backgroundColor: BloomlyColors.paper,
        foregroundColor: BloomlyColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: BloomlyType.display(22),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        height: 64,
        indicatorColor: BloomlyColors.marigold.withValues(alpha: 0.35),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? BloomlyColors.ink : BloomlyColors.muted,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BloomlyColors.gold,
          foregroundColor: BloomlyColors.ink,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: BloomlyType.label.copyWith(color: BloomlyColors.ink),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BloomlyColors.ink,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: BloomlyColors.line),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: BloomlyType.label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BloomlyColors.amber,
          textStyle: BloomlyType.label.copyWith(color: BloomlyColors.amber),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BloomlyColors.card,
        selectedColor: BloomlyColors.ink,
        labelStyle: BloomlyType.label.copyWith(fontSize: 14),
        secondaryLabelStyle: BloomlyType.label.copyWith(
          color: Colors.white,
          fontSize: 14,
        ),
        side: const BorderSide(color: BloomlyColors.line),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      cardTheme: CardThemeData(
        color: BloomlyColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(color: BloomlyColors.line),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BloomlyColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: BloomlyColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: BloomlyColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: BloomlyColors.ink, width: 1.4),
        ),
      ),
    );
  }
}
