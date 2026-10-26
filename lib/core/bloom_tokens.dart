import 'package:flutter/material.dart';

/// Basil & Lime, palette A. Lime is a fill behind ink text only.
abstract final class BloomBrand {
  static const basil = Color(0xFF0B6B4B);
  static const basilDark = Color(0xFF4FD39A);
  static const onBasilDark = Color(0xFF06231A);
  static const basilPressed = Color(0xFF08543B);
  static const lime = Color(0xFFC8F25A);
  static const marigold = Color(0xFFF4A21A);
  static const ink = Color(0xFF0F1F17);
  static const paper = Color(0xFFF5F8F2);
  static const night = Color(0xFF0C1511);
  static const cardDark = Color(0xFF15211B);
  static const textDark = Color(0xFFEAF2EC);
  static const secondaryText = Color(0xFF4E5F55);
  static const secondaryTextDark = Color(0xFFA3B4AA);
  static const success = Color(0xFF1E7A3C);
  static const successDark = Color(0xFF5FD58A);
  static const warning = Color(0xFF8A5A00);
  static const warningDark = Color(0xFFF2B84B);
  static const danger = Color(0xFFC2352B);
  static const dangerDark = Color(0xFFFF8A7E);
}

abstract final class Basil {
  static const s50 = Color(0xFFECFCEA);
  static const s100 = Color(0xFFD7F8D3);
  static const s200 = Color(0xFFB3EFAC);
  static const s300 = Color(0xFF85DF7C);
  static const s400 = Color(0xFF5AC950);
  static const s500 = Color(0xFF45AE3C);
  static const s600 = Color(0xFF389230);
  static const s700 = Color(0xFF2B7724);
  static const s800 = Color(0xFF225D1C);
  static const s900 = Color(0xFF194415);
  static const s950 = Color(0xFF0D2A0B);
}

abstract final class Mango {
  static const s50 = Color(0xFFFFF5ED);
  static const s100 = Color(0xFFFFE8D6);
  static const s200 = Color(0xFFFFD3AD);
  static const s300 = Color(0xFFFEB36F);
  static const s400 = Color(0xFFF68F08);
  static const s500 = Color(0xFFD47A05);
  static const s600 = Color(0xFFB36602);
  static const s700 = Color(0xFF925301);
  static const s800 = Color(0xFF734001);
  static const s900 = Color(0xFF562E00);
  static const s950 = Color(0xFF371B00);
}

/// Petal Pop brand. Light mode only; dark mode stays Basil and Lime.
abstract final class Petal {
  static const s50 = Color(0xFFFFF3F8);
  static const s100 = Color(0xFFFEE5EF);
  static const s200 = Color(0xFFFFCCE1);
  static const s300 = Color(0xFFFEA7CD);
  static const s400 = Color(0xFFFB7AB8);
  static const s500 = Color(0xFFEB50A1);
  static const s600 = Color(0xFFD22B89);
  static const s700 = Color(0xFFAE1E70);
  static const s800 = Color(0xFF891557);
  static const s900 = Color(0xFF641440);
  static const s950 = Color(0xFF400927);
}

/// Plum neutrals from the Petal Pop light ramp.
abstract final class Plum {
  static const s50 = Color(0xFFF9F8FC);
  static const s100 = Color(0xFFF1F0F6);
  static const s200 = Color(0xFFE3E0EA);
  static const s300 = Color(0xFFD0CCDA);
  static const s400 = Color(0xFFA6A1B4);
  static const s500 = Color(0xFF827C93);
  static const s600 = Color(0xFF665E79);
  static const s700 = Color(0xFF4D4561);
  static const s800 = Color(0xFF332B46);
  static const s900 = Color(0xFF1E172E);
  static const s950 = Color(0xFF100B1B);
}

abstract final class Chili {
  static const s50 = Color(0xFFFEF4F3);
  static const s100 = Color(0xFFFFE6E4);
  static const s200 = Color(0xFFFED0CB);
  static const s300 = Color(0xFFFEAEA6);
  static const s400 = Color(0xFFF8867F);
  static const s500 = Color(0xFFE9615C);
  static const s600 = Color(0xFFD14241);
  static const s700 = Color(0xFFAF2F30);
  static const s800 = Color(0xFF8B2324);
  static const s900 = Color(0xFF67191A);
  static const s950 = Color(0xFF420E0E);
}

abstract final class Sky {
  static const s50 = Color(0xFFF1F8FE);
  static const s100 = Color(0xFFE0EFFE);
  static const s200 = Color(0xFFC3E0FE);
  static const s300 = Color(0xFF99CBFE);
  static const s400 = Color(0xFF6FB2F5);
  static const s500 = Color(0xFF4898E6);
  static const s600 = Color(0xFF217FD0);
  static const s700 = Color(0xFF0767B0);
  static const s800 = Color(0xFF01508D);
  static const s900 = Color(0xFF033B68);
  static const s950 = Color(0xFF012443);
}

abstract final class Sun {
  static const s50 = Color(0xFFFFF6E2);
  static const s100 = Color(0xFFFFEBBD);
  static const s200 = Color(0xFFFBD985);
  static const s300 = Color(0xFFEDBF44);
  static const s400 = Color(0xFFD4A502);
  static const s500 = Color(0xFFB68E05);
  static const s600 = Color(0xFF997600);
  static const s700 = Color(0xFF7D6004);
  static const s800 = Color(0xFF624B02);
  static const s900 = Color(0xFF483601);
  static const s950 = Color(0xFF2E2100);
}

const bloomWhite = Color(0xFFFFFFFF);

/// Semantic Basil & Lime colours for one brightness.
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
    required this.etaBg,
    required this.etaFg,
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
  final Color etaBg;
  final Color etaFg;

  bool get isDark => brightness == Brightness.dark;

  static const light = BloomTokens(
    brightness: Brightness.light,
    canvas: Plum.s50,
    surface: bloomWhite,
    raised: bloomWhite,
    sunken: Plum.s100,
    inverse: Plum.s900,
    text: Plum.s900,
    textSecondary: Plum.s600,
    textDisabled: Plum.s400,
    link: Petal.s700,
    textInverse: bloomWhite,
    border: Plum.s200,
    borderStrong: Plum.s500,
    borderFocus: Petal.s600,
    primary: Petal.s600,
    primaryPressed: Petal.s700,
    onPrimary: bloomWhite,
    secondary: Petal.s100,
    onSecondary: Petal.s800,
    strong: Plum.s900,
    onStrong: bloomWhite,
    danger: Chili.s700,
    success: Basil.s700,
    successBg: Basil.s50,
    warning: Sun.s800,
    warningBg: Sun.s50,
    info: Sky.s700,
    infoBg: Sky.s50,
    discountBg: Basil.s700,
    discountFg: bloomWhite,
    washVeg: Basil.s50,
    washFruit: Mango.s50,
    washFlower: Petal.s50,
    awaitingBg: Sun.s100,
    awaitingFg: Sun.s800,
    placedBg: Sky.s100,
    placedFg: Sky.s800,
    packingBg: Mango.s100,
    packingFg: Mango.s800,
    outBg: Petal.s100,
    outFg: Petal.s800,
    deliveredBg: Basil.s100,
    deliveredFg: Basil.s800,
    cancelledBg: Chili.s100,
    cancelledFg: Chili.s800,
    star: Sun.s700,
    etaBg: Petal.s100,
    etaFg: Petal.s800,
  );

  static const dark = BloomTokens(
    brightness: Brightness.dark,
    canvas: BloomBrand.night,
    surface: BloomBrand.cardDark,
    raised: Color(0xFF1C2B24),
    sunken: BloomBrand.night,
    inverse: BloomBrand.textDark,
    text: BloomBrand.textDark,
    textSecondary: BloomBrand.secondaryTextDark,
    textDisabled: Color(0xFF6E8076),
    link: BloomBrand.basilDark,
    textInverse: BloomBrand.night,
    border: Color(0xFF24362E),
    borderStrong: BloomBrand.secondaryTextDark,
    borderFocus: BloomBrand.basilDark,
    primary: BloomBrand.basilDark,
    primaryPressed: Color(0xFF8AE8C0),
    onPrimary: BloomBrand.onBasilDark,
    secondary: Color(0xFF0E3326),
    onSecondary: BloomBrand.basilDark,
    strong: BloomBrand.textDark,
    onStrong: BloomBrand.night,
    danger: BloomBrand.dangerDark,
    success: BloomBrand.successDark,
    successBg: Color(0xFF0E2A1A),
    warning: BloomBrand.warningDark,
    warningBg: Color(0xFF2A2110),
    info: BloomBrand.basilDark,
    infoBg: Color(0xFF0E3326),
    discountBg: BloomBrand.lime,
    discountFg: BloomBrand.ink,
    washVeg: Color(0xFF10281C),
    washFruit: Color(0xFF2A2110),
    washFlower: Color(0xFF2A2414),
    awaitingBg: Color(0xFF2A2110),
    awaitingFg: BloomBrand.warningDark,
    placedBg: Color(0xFF0E3326),
    placedFg: BloomBrand.basilDark,
    packingBg: Color(0xFF2A2110),
    packingFg: BloomBrand.marigold,
    outBg: Color(0xFF0E3326),
    outFg: BloomBrand.basilDark,
    deliveredBg: Color(0xFF0E2A1A),
    deliveredFg: BloomBrand.successDark,
    cancelledBg: Color(0xFF2A1412),
    cancelledFg: BloomBrand.dangerDark,
    star: BloomBrand.marigold,
    etaBg: BloomBrand.lime,
    etaFg: BloomBrand.ink,
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

  List<BoxShadow> get cardShadow => isDark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x141E172E),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ];

  List<BoxShadow> get raisedShadow => isDark
      ? const []
      : const [
          BoxShadow(
            color: Color(0x1F0F1F17),
            blurRadius: 32,
            offset: Offset(0, 12),
          ),
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
    if (tokens != null) return tokens;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return dark ? BloomTokens.dark : BloomTokens.light;
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
    Color? etaBg,
    Color? etaFg,
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
      etaBg: etaBg ?? this.etaBg,
      etaFg: etaFg ?? this.etaFg,
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
      etaBg: mix(etaBg, other.etaBg),
      etaFg: mix(etaFg, other.etaFg),
    );
  }
}

extension BloomTokensContext on BuildContext {
  BloomTokens get bloom => BloomTokens.of(this);

  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}
