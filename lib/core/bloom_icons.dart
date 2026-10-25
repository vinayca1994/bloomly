import 'package:flutter/widgets.dart';

/// Phosphor glyphs from the `phosphor_flutter` font files.
///
/// This Flutter version marks [IconData] final, and phosphor_flutter 2.1.0
/// still subclasses it, so the package library does not compile. The fonts
/// ship with the package; these code points are the same glyphs.
abstract final class BloomIcons {
  static const _regular = 'PhosphorRegular';
  static const _fill = 'PhosphorFill';
  static const _duo = 'PhosphorDuotone';
  static const _pkg = 'phosphor_flutter';

  static const add = IconData(0xe3d4, fontFamily: _regular, fontPackage: _pkg);
  static const arrowDown = IconData(0xe03e, fontFamily: _regular, fontPackage: _pkg);
  static const arrowLeft = IconData(0xe058, fontFamily: _regular, fontPackage: _pkg);
  static const arrowUp = IconData(0xe08e, fontFamily: _regular, fontPackage: _pkg);
  static const basket = IconData(0xe964, fontFamily: _regular, fontPackage: _pkg);
  static const briefcase = IconData(0xe0ee, fontFamily: _regular, fontPackage: _pkg);
  static const caretDown = IconData(0xe136, fontFamily: _regular, fontPackage: _pkg);
  static const caretRight = IconData(0xe13a, fontFamily: _regular, fontPackage: _pkg);
  static const chat = IconData(0xe168, fontFamily: _regular, fontPackage: _pkg);
  static const check = IconData(0xe182, fontFamily: _regular, fontPackage: _pkg);
  static const checkCircle = IconData(0xe184, fontFamily: _regular, fontPackage: _pkg);
  static const close = IconData(0xe4f6, fontFamily: _regular, fontPackage: _pkg);
  static const gear = IconData(0xe270, fontFamily: _regular, fontPackage: _pkg);
  static const history = IconData(0xe1a0, fontFamily: _regular, fontPackage: _pkg);
  static const house = IconData(0xe2c2, fontFamily: _regular, fontPackage: _pkg);
  static const houseFill = IconData(0xe2c2, fontFamily: _fill, fontPackage: _pkg);
  static const image = IconData(0xe2ca, fontFamily: _regular, fontPackage: _pkg);
  static const info = IconData(0xe2ce, fontFamily: _regular, fontPackage: _pkg);
  static const lock = IconData(0xe2fa, fontFamily: _regular, fontPackage: _pkg);
  static const mapPin = IconData(0xe316, fontFamily: _regular, fontPackage: _pkg);
  static const megaphone = IconData(0xe324, fontFamily: _regular, fontPackage: _pkg);
  static const minus = IconData(0xe32a, fontFamily: _regular, fontPackage: _pkg);
  static const money = IconData(0xe588, fontFamily: _regular, fontPackage: _pkg);
  static const more = IconData(0xe1fe, fontFamily: _regular, fontPackage: _pkg);
  static const moped = IconData(0xe824, fontFamily: _regular, fontPackage: _pkg);
  static const navigation = IconData(0xeade, fontFamily: _regular, fontPackage: _pkg);
  static const package = IconData(0xe390, fontFamily: _regular, fontPackage: _pkg);
  static const phone = IconData(0xe3b8, fontFamily: _regular, fontPackage: _pkg);
  static const plant = IconData(0xebae, fontFamily: _regular, fontPackage: _pkg);
  static const receipt = IconData(0xe3ec, fontFamily: _regular, fontPackage: _pkg);
  static const receiptFill = IconData(0xe3ec, fontFamily: _fill, fontPackage: _pkg);
  static const search = IconData(0xe30c, fontFamily: _regular, fontPackage: _pkg);
  static const shield = IconData(0xe40a, fontFamily: _regular, fontPackage: _pkg);
  static const shoppingBag = IconData(0xe416, fontFamily: _regular, fontPackage: _pkg);
  static const signOut = IconData(0xe42a, fontFamily: _regular, fontPackage: _pkg);
  static const squares = IconData(0xe464, fontFamily: _regular, fontPackage: _pkg);
  static const squaresFill = IconData(0xe464, fontFamily: _fill, fontPackage: _pkg);
  static const star = IconData(0xe46a, fontFamily: _regular, fontPackage: _pkg);
  static const starFill = IconData(0xe46a, fontFamily: _fill, fontPackage: _pkg);
  static const storefront = IconData(0xe470, fontFamily: _regular, fontPackage: _pkg);
  static const sun = IconData(0xe472, fontFamily: _regular, fontPackage: _pkg);
  static const trash = IconData(0xe4a6, fontFamily: _regular, fontPackage: _pkg);
  static const truck = IconData(0xe4b4, fontFamily: _regular, fontPackage: _pkg);
  static const user = IconData(0xe4c2, fontFamily: _regular, fontPackage: _pkg);
  static const userFill = IconData(0xe4c2, fontFamily: _fill, fontPackage: _pkg);
  static const wallet = IconData(0xe68a, fontFamily: _regular, fontPackage: _pkg);

  static const squaresDuo = (IconData(0xe464, fontFamily: _duo, fontPackage: _pkg), IconData(0xe465, fontFamily: _duo, fontPackage: _pkg));
  static const plantDuo = (IconData(0xebae, fontFamily: _duo, fontPackage: _pkg), IconData(0xebaf, fontFamily: _duo, fontPackage: _pkg));
  static const orangeDuo = (IconData(0xed36, fontFamily: _duo, fontPackage: _pkg), IconData(0xed37, fontFamily: _duo, fontPackage: _pkg));
  static const flowerDuo = (IconData(0xe75e, fontFamily: _duo, fontPackage: _pkg), IconData(0xe75f, fontFamily: _duo, fontPackage: _pkg));
  static const lotusDuo = (IconData(0xe6cc, fontFamily: _duo, fontPackage: _pkg), IconData(0xe6cd, fontFamily: _duo, fontPackage: _pkg));
  static const giftDuo = (IconData(0xe276, fontFamily: _duo, fontPackage: _pkg), IconData(0xe277, fontFamily: _duo, fontPackage: _pkg));
  static const lampDuo = (IconData(0xe638, fontFamily: _duo, fontPackage: _pkg), IconData(0xe639, fontFamily: _duo, fontPackage: _pkg));
}

/// Duotone is two glyphs: a faint back shape and the front stroke.
class BloomDuotone extends StatelessWidget {
  const BloomDuotone(
    this.pair, {
    this.size = 24,
    this.color,
    super.key,
  });

  final (IconData, IconData) pair;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0.35,
            child: Icon(pair.$1, size: size, color: color),
          ),
          Icon(pair.$2, size: size, color: color),
        ],
      ),
    );
  }
}
