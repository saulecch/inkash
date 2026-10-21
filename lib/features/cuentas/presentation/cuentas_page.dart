import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/core/format/formato_moneda.dart';
import 'package:inkash/core/ui/hoja_formulario.dart';
import 'package:inkash/core/ui/monto.dart';
import 'package:inkash/core/ui/seccion.dart';
import 'package:inkash/core/widgets/iconos.dart';
import 'package:inkash/features/cuentas/domain/cuenta.dart';
import 'package:inkash/features/cuentas/presentation/cuenta_sheet.dart';
import 'package:inkash/features/cuentas/presentation/cuentas_provider.dart';
import 'package:inkash/features/historial/historial_controller.dart';
import 'package:inkash/features/home/presentation/controllers/home_controller.dart';
import 'package:inkash/theme.dart';

// Se abre con Navigator.push desde la tarjeta "Cuentas" del Inicio.
class CuentasPage extends ConsumerWidget {
  const CuentasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentas = ref.watch(cuentasProvider);
    final texto = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva cuenta'),
      ),
      body: cuentas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(cuentasProvider),
            child: const Text('No pudimos leer tus cuentas. Reintentar'),
          ),
        ),
        data: (lista) {
          final total = lista.fold(0, (t, c) => t + c.saldoCentavos);
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Espacio.l,
                  Espacio.s,
                  Espacio.l,
                  Espacio.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total en tus cuentas', style: texto.bodySmall),
                    Monto(
                      total,
                      estilo: texto.displayLarge?.copyWith(fontSize: 40),
                    ),
                  ],
                ),
              ),
              Seccion(
                titulo: 'Toca una cuenta para editarla',
                children: [
                  for (final cuenta in lista)
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: kIconoFondo,
                        child: Icon(iconoDe(cuenta.icono), color: kLima),
                      ),
                      title: Text(cuenta.nombre),
                      subtitle: Text(
                        'Inicial ${formatQuetzales(cuenta.saldoInicialCentavos)}',
                        style: texto.bodySmall,
                      ),
                      trailing: Monto(cuenta.saldoCentavos, colorear: true),
                      onTap: () =>
                          _abrirFormulario(context, ref, cuenta: cuenta),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _abrirFormulario(
    BuildContext context,
    WidgetRef ref, {
    Cuenta? cuenta,
  }) {
    final repo = ref.read(cuentasRepositoryProvider);
    // El nombre de la cuenta aparece en los movimientos ("Súper · Banco"):
    // al cambiarla hay que refrescar también Inicio e Historial.
    void refrescar() {
      ref.invalidate(cuentasProvider);
      ref.invalidate(homeControllerProvider);
      ref.invalidate(historialProvider);
    }

    return mostrarHoja<void>(
      context,
      (_) => CuentaSheet(
        cuenta: cuenta,
        onGuardar: (d) async {
          await repo.guardar(
            id: cuenta?.id,
            nombre: d.nombre,
            icono: d.icono,
            saldoInicialCentavos: d.saldoInicialCentavos,
          );
          refrescar();
        },
        onEliminar: cuenta == null
            ? null
            : () async {
                await repo.eliminar(cuenta.id);
                refrescar();
              },
      ),
    );
  }
}
