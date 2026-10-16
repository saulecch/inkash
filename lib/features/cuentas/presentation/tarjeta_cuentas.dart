import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/core/format/formato_moneda.dart';
import 'package:inkash/features/cuentas/presentation/cuentas_page.dart';
import 'package:inkash/features/cuentas/presentation/cuentas_provider.dart';
import 'package:inkash/theme.dart';

// Tarjeta "Cuentas" del Inicio: antes decía 'Q7,810.00' escrito a mano.
// Tocarla abre la pantalla Cuentas (crear, editar, saldo inicial).
class TarjetaCuentas extends ConsumerWidget {
  const TarjetaCuentas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentas = ref.watch(cuentasProvider);
    final total = cuentas.whenOrNull(
      data: (lista) => lista.fold(0, (t, c) => t + c.saldoCentavos),
    );

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        // s16-01: abre la gestión de cuentas (antes era solo un detalle).
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const CuentasPage())),
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
                'Cuentas',
                style: TextStyle(fontSize: 11, color: kMuted),
              ),
              const SizedBox(height: 2),
              // Estado compacto: "…" cargando, "—" error, el total si hay datos.
              Text(
                cuentas.isLoading
                    ? '…'
                    : total == null
                    ? '—'
                    : formatQuetzales(total),
                style: const TextStyle(fontSize: 19),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
