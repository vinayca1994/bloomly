import 'dart:io';

import 'package:bloomly/core/bloom_icons.dart';
import 'package:bloomly/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('The shop uses one light paper and leaf palette', () {
    final light = BloomlyTheme.light();
    final tokens = light.extension<BloomTokens>();

    expect(light.brightness, Brightness.light);
    expect(tokens?.primary, Market.green);
    expect(tokens?.canvas, Market.canvas);
    expect(tokens?.text, Market.ink);
    expect(tokens?.onPrimary, bloomWhite);
    expect(tokens?.discountBg, Market.offer);
    expect(tokens?.discountFg, Market.offerInk);
    expect(tokens?.link, Market.green);
    expect(light.textTheme.bodyLarge?.fontSize, 17);
    expect(light.textTheme.labelLarge?.fontWeight, FontWeight.w600);
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
