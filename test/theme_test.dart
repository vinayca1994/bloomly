import 'package:bloomly/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Petal Pop light and dark tokens are on the theme', () {
    final light = BloomlyTheme.light();
    final dark = BloomlyTheme.dark();

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.extension<BloomTokens>()?.primary, Petal.s600);
    expect(dark.extension<BloomTokens>()?.primary, Petal.s400);
    expect(light.extension<BloomTokens>()?.canvas, Plum.s50);
    expect(dark.extension<BloomTokens>()?.canvas, Plum.s950);
    expect(light.extension<BloomTokens>()?.success, Basil.s700);
    expect(light.extension<BloomTokens>()?.danger, Chili.s700);
  });
}
