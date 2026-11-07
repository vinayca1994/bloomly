import 'package:flutter/widgets.dart';

import 'bloom_tokens.dart';

/// Mobile and tests. Plus Jakarta has no emoji, so this text does not inherit
/// the shop font. The colour is set because a non-inherited style is white
/// off the web.
Widget bloomEmoji(String emoji, double size, [Color? color]) {
  return Text(
    emoji,
    style: TextStyle(
      inherit: false,
      color: color ?? Market.ink,
      fontSize: size,
      height: 1.1,
    ),
  );
}
