import 'dart:io';

import 'package:bloomly/core/bloom_icons.dart';
import 'package:bloomly/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Light is Petal Pop and dark stays Basil and Lime', () {
    final light = BloomlyTheme.light();
    final dark = BloomlyTheme.dark();

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.extension<BloomTokens>()?.primary, Petal.s600);
    expect(light.extension<BloomTokens>()?.canvas, Plum.s50);
    expect(light.extension<BloomTokens>()?.text, Plum.s900);
    expect(light.extension<BloomTokens>()?.onPrimary, bloomWhite);
    expect(light.extension<BloomTokens>()?.discountBg, Basil.s700);
    expect(light.extension<BloomTokens>()?.discountFg, bloomWhite);
    expect(light.extension<BloomTokens>()?.link, Petal.s700);
    expect(dark.extension<BloomTokens>()?.primary, BloomBrand.basilDark);
    expect(dark.extension<BloomTokens>()?.canvas, BloomBrand.night);
    expect(dark.extension<BloomTokens>()?.text, BloomBrand.textDark);
    expect(dark.extension<BloomTokens>()?.onPrimary, BloomBrand.onBasilDark);
    expect(dark.extension<BloomTokens>()?.discountBg, BloomBrand.lime);
    expect(dark.extension<BloomTokens>()?.discountFg, BloomBrand.ink);
    expect(dark.extension<BloomTokens>()?.success, BloomBrand.successDark);
    expect(dark.extension<BloomTokens>()?.danger, BloomBrand.dangerDark);
    expect(BloomIcons.house.fontFamily, 'MaterialIcons');
    expect(BloomIcons.houseFill, Icons.home_rounded);
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
