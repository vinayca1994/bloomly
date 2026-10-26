import 'dart:js_interop';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// CanvasKit downloads Noto for emoji, and that fetch fails on this shop's
/// network. A plain span uses the browser's own emoji font.
Widget bloomEmoji(String emoji, double size, [Color? color]) {
  return SizedBox(
    width: size,
    height: size,
    child: HtmlElementView.fromTagName(
      tagName: 'span',
      hitTestBehavior: PlatformViewHitTestBehavior.transparent,
      onElementCreated: (element) {
        final node = _EmojiNode(element as JSObject);
        node.textContent = emoji;
        final style = node.style;
        style.fontSize = '${size}px';
        style.lineHeight = '1';
        style.display = 'flex';
        style.alignItems = 'center';
        style.justifyContent = 'center';
        style.width = '100%';
        style.height = '100%';
        style.pointerEvents = 'none';
      },
    ),
  );
}

extension type _EmojiNode(JSObject _) implements JSObject {
  external set textContent(String? value);
  external _EmojiStyle get style;
}

extension type _EmojiStyle(JSObject _) implements JSObject {
  external set fontSize(String value);
  external set lineHeight(String value);
  external set display(String value);
  external set alignItems(String value);
  external set justifyContent(String value);
  external set width(String value);
  external set height(String value);
  external set pointerEvents(String value);
}
