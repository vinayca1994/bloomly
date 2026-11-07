import 'package:flutter/material.dart';

/// Paper shop. Leaf is the action. Ink is the price. Red is an error.
abstract final class Market {
  static const canvas = Color(0xFFF4F2ED);
  static const tray = Color(0xFFEBE8E1);
  static const ink = Color(0xFF1B1A17);
  static const secondary = Color(0xFF5C5952);
  static const tertiary = Color(0xFF8A867C);
  static const hairline = Color(0xFFE4E0D8);
  static const line = Color(0xFFC9C4B8);
  static const green = Color(0xFF146C36);
  static const greenPressed = Color(0xFF0E5228);
  static const greenWash = Color(0xFFE5F2EA);
  static const red = Color(0xFFB42318);
  static const offer = greenWash;
  static const offerInk = greenPressed;
  static const fruit = Color(0xFFFFF1E4);
  static const flower = Color(0xFFFDE8F1);
}

/// Status hues stay off the brand so Delivered is not the accent.
abstract final class Status {
  static const dangerBg = Color(0xFFFDECEA);
  static const warning = Color(0xFF8A5A00);
  static const warningBg = Color(0xFFFFF6E2);
  static const star = Color(0xFFB7810A);
  static const packingBg = Color(0xFFFFF1E6);
  static const packingFg = Color(0xFF9A4B12);
}

/// Festival poster grounds. These are not the shop chrome.
abstract final class Poster {
  static const pine = Color(0xFF145C38);
  static const harvest = Color(0xFFE39B2B);
  static const cream = Color(0xFFFFF6E4);
  static const citrus = Color(0xFFC46A12);
  static const red = Color(0xFFDC2626);
  static const night = Color(0xFF101412);
  static const nightInk = Color(0xFFF3F7F4);
  static const lime = Color(0xFF3DDC7A);
}

const bloomWhite = Color(0xFFFFFFFF);

/// Semantic market colours for one brightness.
class BloomTokens extends ThemeExtension<BloomTokens> {
  const BloomTokens({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.raised,
    required this.sunken,
    required this.inverse,
    required this.text,
    required this.textSecondary,
    required this.textDisabled,
    required this.link,
    required this.textInverse,
    required this.border,
    required this.borderStrong,
    required this.borderFocus,
    required this.primary,
    required this.primaryPressed,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.strong,
    required this.onStrong,
    required this.danger,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.info,
    required this.infoBg,
    required this.discountBg,
    required this.discountFg,
    required this.washVeg,
    required this.washFruit,
    required this.washFlower,
    required this.awaitingBg,
    required this.awaitingFg,
    required this.placedBg,
    required this.placedFg,
    required this.packingBg,
    required this.packingFg,
    required this.outBg,
    required this.outFg,
    required this.deliveredBg,
    required this.deliveredFg,
    required this.cancelledBg,
    required this.cancelledFg,
    required this.star,
  });

  final Brightness brightness;
  final Color canvas;
  final Color surface;
  final Color raised;
  final Color sunken;
  final Color inverse;
  final Color text;
  final Color textSecondary;
  final Color textDisabled;
  final Color link;
  final Color textInverse;
  final Color border;
  final Color borderStrong;
  final Color borderFocus;
  final Color primary;
  final Color primaryPressed;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color strong;
  final Color onStrong;
  final Color danger;
  final Color success;
  final Color successBg;
  final Color warning;
  final Color warningBg;
  final Color info;
  final Color infoBg;
  final Color discountBg;
  final Color discountFg;
  final Color washVeg;
  final Color washFruit;
  final Color washFlower;
  final Color awaitingBg;
  final Color awaitingFg;
  final Color placedBg;
  final Color placedFg;
  final Color packingBg;
  final Color packingFg;
  final Color outBg;
  final Color outFg;
  final Color deliveredBg;
  final Color deliveredFg;
  final Color cancelledBg;
  final Color cancelledFg;
  final Color star;

  static const light = BloomTokens(
    brightness: Brightness.light,
    canvas: Market.canvas,
    surface: bloomWhite,
    raised: bloomWhite,
    sunken: Market.tray,
    inverse: Market.ink,
    text: Market.ink,
    textSecondary: Market.secondary,
    textDisabled: Market.tertiary,
    link: Market.green,
    textInverse: bloomWhite,
    border: Market.hairline,
    borderStrong: Market.line,
    borderFocus: Market.green,
    primary: Market.green,
    primaryPressed: Market.greenPressed,
    onPrimary: bloomWhite,
    secondary: Market.greenWash,
    onSecondary: Market.greenPressed,
    strong: Market.ink,
    onStrong: bloomWhite,
    danger: Market.red,
    success: Market.green,
    successBg: Market.greenWash,
    warning: Status.warning,
    warningBg: Status.warningBg,
    info: Market.ink,
    infoBg: Market.tray,
    discountBg: Market.offer,
    discountFg: Market.offerInk,
    washVeg: Market.greenWash,
    washFruit: Market.fruit,
    washFlower: Market.flower,
    awaitingBg: Status.warningBg,
    awaitingFg: Status.warning,
    placedBg: Market.tray,
    placedFg: Market.ink,
    packingBg: Status.packingBg,
    packingFg: Status.packingFg,
    outBg: Market.greenWash,
    outFg: Market.greenPressed,
    deliveredBg: Market.greenWash,
    deliveredFg: Market.greenPressed,
    cancelledBg: Status.dangerBg,
    cancelledFg: Market.red,
    star: Status.star,
  );

  static const fast = Duration(milliseconds: 150);
  static const baseMotion = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 420);
  static const easeStandard = Cubic(0.2, 0, 0, 1);
  static const easeEmphasized = Cubic(0.3, 0, 0, 1.2);

  static const radiusXs = 8.0;
  static const radiusSm = 12.0;
  static const radiusMd = 16.0;
  static const radiusLg = 20.0;
  static const radiusXl = 24.0;
  static const radius2xl = 32.0;

  List<BoxShadow> get cardShadow => const [];

  List<BoxShadow> get raisedShadow => const [
    BoxShadow(color: Color(0x141C1C1E), blurRadius: 24, offset: Offset(0, 8)),
  ];

  (Color bg, Color fg) status(String status) {
    return switch (status) {
      'payment_pending' => (awaitingBg, awaitingFg),
      'placed' => (placedBg, placedFg),
      'packing' => (packingBg, packingFg),
      'out_for_delivery' => (outBg, outFg),
      'delivered' => (deliveredBg, deliveredFg),
      'cancelled' => (cancelledBg, cancelledFg),
      _ => (sunken, textSecondary),
    };
  }

  Color washFor(String kind) {
    return switch (kind) {
      'flower' => washFlower,
      'fruit' => washFruit,
      _ => washVeg,
    };
  }

  static BloomTokens of(BuildContext context) {
    final tokens = Theme.of(context).extension<BloomTokens>();
    return tokens ?? BloomTokens.light;
  }

  @override
  BloomTokens copyWith({
    Brightness? brightness,
    Color? canvas,
    Color? surface,
    Color? raised,
    Color? sunken,
    Color? inverse,
    Color? text,
    Color? textSecondary,
    Color? textDisabled,
    Color? link,
    Color? textInverse,
    Color? border,
    Color? borderStrong,
    Color? borderFocus,
    Color? primary,
    Color? primaryPressed,
    Color? onPrimary,
    Color? secondary,
    Color? onSecondary,
    Color? strong,
    Color? onStrong,
    Color? danger,
    Color? success,
    Color? successBg,
    Color? warning,
    Color? warningBg,
    Color? info,
    Color? infoBg,
    Color? discountBg,
    Color? discountFg,
    Color? washVeg,
    Color? washFruit,
    Color? washFlower,
    Color? awaitingBg,
    Color? awaitingFg,
    Color? placedBg,
    Color? placedFg,
    Color? packingBg,
    Color? packingFg,
    Color? outBg,
    Color? outFg,
    Color? deliveredBg,
    Color? deliveredFg,
    Color? cancelledBg,
    Color? cancelledFg,
    Color? star,
  }) {
    return BloomTokens(
      brightness: brightness ?? this.brightness,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      raised: raised ?? this.raised,
      sunken: sunken ?? this.sunken,
      inverse: inverse ?? this.inverse,
      text: text ?? this.text,
      textSecondary: textSecondary ?? this.textSecondary,
      textDisabled: textDisabled ?? this.textDisabled,
      link: link ?? this.link,
      textInverse: textInverse ?? this.textInverse,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      borderFocus: borderFocus ?? this.borderFocus,
      primary: primary ?? this.primary,
      primaryPressed: primaryPressed ?? this.primaryPressed,
      onPrimary: onPrimary ?? this.onPrimary,
      secondary: secondary ?? this.secondary,
      onSecondary: onSecondary ?? this.onSecondary,
      strong: strong ?? this.strong,
      onStrong: onStrong ?? this.onStrong,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      successBg: successBg ?? this.successBg,
      warning: warning ?? this.warning,
      warningBg: warningBg ?? this.warningBg,
      info: info ?? this.info,
      infoBg: infoBg ?? this.infoBg,
      discountBg: discountBg ?? this.discountBg,
      discountFg: discountFg ?? this.discountFg,
      washVeg: washVeg ?? this.washVeg,
      washFruit: washFruit ?? this.washFruit,
      washFlower: washFlower ?? this.washFlower,
      awaitingBg: awaitingBg ?? this.awaitingBg,
      awaitingFg: awaitingFg ?? this.awaitingFg,
      placedBg: placedBg ?? this.placedBg,
      placedFg: placedFg ?? this.placedFg,
      packingBg: packingBg ?? this.packingBg,
      packingFg: packingFg ?? this.packingFg,
      outBg: outBg ?? this.outBg,
      outFg: outFg ?? this.outFg,
      deliveredBg: deliveredBg ?? this.deliveredBg,
      deliveredFg: deliveredFg ?? this.deliveredFg,
      cancelledBg: cancelledBg ?? this.cancelledBg,
      cancelledFg: cancelledFg ?? this.cancelledFg,
      star: star ?? this.star,
    );
  }

  @override
  BloomTokens lerp(ThemeExtension<BloomTokens>? other, double t) {
    if (other is! BloomTokens) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return BloomTokens(
      brightness: t < 0.5 ? brightness : other.brightness,
      canvas: mix(canvas, other.canvas),
      surface: mix(surface, other.surface),
      raised: mix(raised, other.raised),
      sunken: mix(sunken, other.sunken),
      inverse: mix(inverse, other.inverse),
      text: mix(text, other.text),
      textSecondary: mix(textSecondary, other.textSecondary),
      textDisabled: mix(textDisabled, other.textDisabled),
      link: mix(link, other.link),
      textInverse: mix(textInverse, other.textInverse),
      border: mix(border, other.border),
      borderStrong: mix(borderStrong, other.borderStrong),
      borderFocus: mix(borderFocus, other.borderFocus),
      primary: mix(primary, other.primary),
      primaryPressed: mix(primaryPressed, other.primaryPressed),
      onPrimary: mix(onPrimary, other.onPrimary),
      secondary: mix(secondary, other.secondary),
      onSecondary: mix(onSecondary, other.onSecondary),
      strong: mix(strong, other.strong),
      onStrong: mix(onStrong, other.onStrong),
      danger: mix(danger, other.danger),
      success: mix(success, other.success),
      successBg: mix(successBg, other.successBg),
      warning: mix(warning, other.warning),
      warningBg: mix(warningBg, other.warningBg),
      info: mix(info, other.info),
      infoBg: mix(infoBg, other.infoBg),
      discountBg: mix(discountBg, other.discountBg),
      discountFg: mix(discountFg, other.discountFg),
      washVeg: mix(washVeg, other.washVeg),
      washFruit: mix(washFruit, other.washFruit),
      washFlower: mix(washFlower, other.washFlower),
      awaitingBg: mix(awaitingBg, other.awaitingBg),
      awaitingFg: mix(awaitingFg, other.awaitingFg),
      placedBg: mix(placedBg, other.placedBg),
      placedFg: mix(placedFg, other.placedFg),
      packingBg: mix(packingBg, other.packingBg),
      packingFg: mix(packingFg, other.packingFg),
      outBg: mix(outBg, other.outBg),
      outFg: mix(outFg, other.outFg),
      deliveredBg: mix(deliveredBg, other.deliveredBg),
      deliveredFg: mix(deliveredFg, other.deliveredFg),
      cancelledBg: mix(cancelledBg, other.cancelledBg),
      cancelledFg: mix(cancelledFg, other.cancelledFg),
      star: mix(star, other.star),
    );
  }
}

extension BloomTokensContext on BuildContext {
  BloomTokens get bloom => BloomTokens.of(this);

  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}
