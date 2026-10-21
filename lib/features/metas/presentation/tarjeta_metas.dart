import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/features/metas/presentation/metas_page.dart';
import 'package:inkash/features/metas/presentation/metas_provider.dart';
import 'package:inkash/theme.dart';

// Tarjeta "Metas de ahorro" del Inicio: antes decía '3 activas' a mano.
class TarjetaMetas extends ConsumerWidget {
  const TarjetaMetas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metas = ref.watch(metasProvider);
    final activas = metas.value?.where((m) => !m.completada).length;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        // push: una pantalla ENCIMA de las pestañas, con botón para volver.
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const MetasPage())),
        child: Container(
          decoration: BoxDecoration(
            color: kSuperficie,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: kBorde),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Metas de ahorro',
                style: TextStyle(fontSize: 11, color: kMuted),
              ),
              const SizedBox(height: 2),
              Text(switch (activas) {
                null => metas.isLoading ? '…' : '—',
                0 => 'Crear una',
                1 => '1 activa',
                _ => '$activas activas',
              }, style: const TextStyle(fontSize: 19)),
            ],
          ),
        ),
      ),
    );
  }
}
