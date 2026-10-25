import 'dart:io';

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
    expect(light.textTheme.bodyMedium?.fontFamily, BloomlyType.ui);
    expect(light.textTheme.bodyMedium?.fontFamilyFallback, [BloomlyType.ui]);
    expect(light.textTheme.headlineLarge?.fontFamily, isNot('Roboto'));
    for (final style in <TextStyle?>[
      light.textTheme.bodyLarge,
      light.textTheme.bodyMedium,
      light.textTheme.labelLarge,
      light.textTheme.titleMedium,
      dark.textTheme.bodyMedium,
    ]) {
      expect(style?.fontFamily, isNot('Roboto'));
    }
  });

  test('the font manifest ships a local Roboto so web does not fetch it', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      pubspec,
      contains(
        RegExp(
          r'family: Roboto\s+fonts:\s+- asset: assets/fonts/PlusJakartaSans\.ttf',
        ),
      ),
    );
  });
}
