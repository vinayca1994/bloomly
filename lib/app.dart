import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'data/providers.dart';
import 'features/account/lock_gate.dart';

class BloomlyApp extends ConsumerWidget {
  const BloomlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final base = BloomlyTheme.light();
    return MaterialApp.router(
      title: 'Bloomly',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
        primaryTextTheme: GoogleFonts.plusJakartaSansTextTheme(base.primaryTextTheme),
      ),
      routerConfig: router,
      builder: (context, child) {
        final backend = ref.watch(backendProvider);
        if (!backend.ready) {
          return const ColoredBox(
            color: BloomlyColors.background,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (backend.loadError != null) {
          return ColoredBox(
            color: BloomlyColors.background,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(backend.loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.read(backendProvider).reload(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return LockGate(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
