import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/features/ajustes/presentation/ajustes_controller.dart';
import 'package:inkash/features/bienvenida/bienvenida_page.dart';
import 'package:inkash/shell.dart';
import 'package:inkash/theme.dart';

// Ya no recibe el controlador: cada pantalla lo pide con ref.watch.
// s15-01: la pantalla raíz es el cascarón con las pestañas.
// s17-03: la raíz decide entre la bienvenida y las pestañas mirando Ajustes.
class InkashApp extends ConsumerWidget {
  const InkashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bienvenidaCompleta = ref.watch(
      ajustesProvider.select((a) => a.whenData((x) => x.bienvenidaCompleta)),
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inkash',
      theme: buildInkashTheme(),
      home: bienvenidaCompleta.when(
        // Un instante al abrir: fondo de la app, sin parpadeo blanco.
        loading: () => const Scaffold(),
        // Si no se pueden leer los ajustes, no bloqueamos la app.
        error: (_, _) => const InkashShell(),
        data: (completa) =>
            completa ? const InkashShell() : const BienvenidaPage(),
      ),
    );
  }
}
