import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/features/metas/presentation/metas_page.dart';
import 'package:inkash/features/metas/presentation/metas_provider.dart';
import 'package:inkash/core/ui/tarjeta_resumen.dart';

// Tarjeta "Metas de ahorro" del Inicio: antes decía '3 activas' a mano.
class TarjetaMetas extends ConsumerWidget {
  const TarjetaMetas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metas = ref.watch(metasProvider);
    final activas = metas.value?.where((m) => !m.completada).length;

    return TarjetaResumen(
      icono: Icons.savings_outlined,
      etiqueta: 'Metas de ahorro',
      valor: switch (activas) {
        null => metas.isLoading ? '…' : '—',
        0 => 'Crear una',
        1 => '1 activa',
        _ => '$activas activas',
      },
      // push: una pantalla ENCIMA de las pestañas, con botón para volver.
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const MetasPage())),
    );
  }
}
