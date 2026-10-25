import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'data/providers.dart';
import 'features/brand/launch_screen.dart';

class BloomlyApp extends ConsumerStatefulWidget {
  const BloomlyApp({super.key});

  @override
  ConsumerState<BloomlyApp> createState() => _BloomlyAppState();
}

class _BloomlyAppState extends ConsumerState<BloomlyApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(ref.read(backendProvider).onForeground());
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final base = BloomlyTheme.light();
    return MaterialApp.router(
      title: 'Bloom',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: base.textTheme.apply(fontFamily: 'PlusJakartaSans'),
        primaryTextTheme: base.primaryTextTheme.apply(
          fontFamily: 'PlusJakartaSans',
        ),
      ),
      routerConfig: router,
      builder: (context, child) => LaunchGate(child: child),
    );
  }
}
