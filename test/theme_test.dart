import 'dart:io';

import 'package:bloomly/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Basil and Lime light and dark tokens are on the theme', () {
    final light = BloomlyTheme.light();
    final dark = BloomlyTheme.dark();

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.extension<BloomTokens>()?.primary, BloomBrand.basil);
    expect(dark.extension<BloomTokens>()?.primary, BloomBrand.basilDark);
    expect(light.extension<BloomTokens>()?.canvas, BloomBrand.paper);
    expect(dark.extension<BloomTokens>()?.canvas, BloomBrand.night);
    expect(light.extension<BloomTokens>()?.text, BloomBrand.ink);
    expect(dark.extension<BloomTokens>()?.text, BloomBrand.textDark);
    expect(light.extension<BloomTokens>()?.onPrimary, bloomWhite);
    expect(dark.extension<BloomTokens>()?.onPrimary, BloomBrand.onBasilDark);
    expect(light.extension<BloomTokens>()?.discountBg, BloomBrand.lime);
    expect(light.extension<BloomTokens>()?.discountFg, BloomBrand.ink);
    expect(dark.extension<BloomTokens>()?.discountFg, BloomBrand.ink);
    expect(light.extension<BloomTokens>()?.success, BloomBrand.success);
    expect(dark.extension<BloomTokens>()?.success, BloomBrand.successDark);
    expect(light.extension<BloomTokens>()?.danger, BloomBrand.danger);
    expect(dark.extension<BloomTokens>()?.danger, BloomBrand.dangerDark);
    expect(light.extension<BloomTokens>()?.star, BloomBrand.marigold);
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
