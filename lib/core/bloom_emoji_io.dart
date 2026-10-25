import 'package:flutter/widgets.dart';

/// Mobile and tests. Plus Jakarta has no emoji, so this text does not inherit
/// the shop font. The colour is set because a non-inherited style is white
/// off the web.
Widget bloomEmoji(String emoji, double size) {
  return Text(
    emoji,
    style: TextStyle(
      inherit: false,
      color: const Color(0xFF1C1917),
      fontSize: size,
      height: 1.1,
    ),
  );
}
