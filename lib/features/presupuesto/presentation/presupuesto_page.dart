import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/core/format/formato_fecha.dart';
import 'package:inkash/core/format/formato_moneda.dart';
import 'package:inkash/core/reloj.dart';
import 'package:inkash/core/widgets/hoja_monto.dart';
import 'package:inkash/core/widgets/iconos.dart';
import 'package:inkash/features/presupuesto/domain/presupuesto_categoria.dart';
import 'package:inkash/features/presupuesto/presentation/presupuesto_provider.dart';
import 'package:inkash/theme.dart';

class PresupuestoPage extends ConsumerWidget {
  const PresupuestoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presupuesto = ref.watch(presupuestoProvider);
    final mes = ref.watch(relojProvider)();

    return SafeArea(
      child: presupuesto.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(presupuestoProvider),
            child: const Text('No pudimos leer el presupuesto. Reintentar'),
          ),
        ),
        data: (filas) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Presupuesto · ${nombreMes(mes)}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 4),
            const Text(
              'Toca una categoría para definir su límite mensual.',
              style: TextStyle(color: kMuted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _Resumen(filas: filas),
            const SizedBox(height: 8),
            for (final fila in filas)
              _FilaPresupuesto(
                fila: fila,
                onTap: () => _editarLimite(context, ref, fila),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editarLimite(
    BuildContext context,
    WidgetRef ref,
    PresupuestoCategoria fila,
  ) async {
    final respuesta = await pedirMonto(
      context,
      titulo: 'Límite para ${fila.nombre}',
      ayuda: 'Cuánto quieres gastar como máximo cada mes.',
      inicialCentavos: fila.limiteCentavos,
      acciones: [if (fila.limiteCentavos != null) 'Quitar límite', 'Guardar'],
    );
    if (respuesta == null) return;
    await ref
        .read(presupuestoRepositoryProvider)
        .definirLimite(
          fila.categoriaId,
          respuesta.accion == 'Guardar' ? respuesta.centavos : null,
        );
    ref.invalidate(presupuestoProvider);
  }
}

class _FilaPresupuesto extends StatelessWidget {
  const _FilaPresupuesto({required this.fila, required this.onTap});

  final PresupuestoCategoria fila;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final limite = fila.limiteCentavos;
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(iconoDe(fila.icono), color: kLima),
      title: Text(fila.nombre),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          if (fila.progreso != null)
            LinearProgressIndicator(
              value: fila.progreso,
              minHeight: 6,
              color: fila.excedido ? kPeligro : kLima,
            ),
          const SizedBox(height: 4),
          Text(
            limite == null
                ? 'Gastado ${formatQuetzales(fila.gastadoCentavos)} · sin límite'
                : '${formatQuetzales(fila.gastadoCentavos)} de '
                      '${formatQuetzales(limite)}'
                      '${fila.excedido ? ' · excedido' : ''}',
            style: TextStyle(
              fontSize: 12,
              color: fila.excedido ? kPeligro : kMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// Total de lo presupuestado y lo gastado en esas categorías.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.filas});

  final List<PresupuestoCategoria> filas;

  @override
  Widget build(BuildContext context) {
    final conLimite = filas.where((f) => f.limiteCentavos != null);
    if (conLimite.isEmpty) {
      return const Text(
        'Aún no tienes límites. Empieza por la categoría donde más gastas.',
        style: TextStyle(color: kMuted),
      );
    }
    final limite = conLimite.fold(0, (t, f) => t + f.limiteCentavos!);
    final gastado = conLimite.fold(0, (t, f) => t + f.gastadoCentavos);
    final excedidas = conLimite.where((f) => f.excedido).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSuperficie,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: kBorde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Te quedan ${formatQuetzales(limite - gastado)}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatQuetzales(gastado)} de ${formatQuetzales(limite)}'
            '${excedidas > 0 ? ' · $excedidas excedida${excedidas > 1 ? 's' : ''}' : ''}',
            style: TextStyle(
              fontSize: 12,
              color: excedidas > 0 ? kPeligro : kMuted,
            ),
          ),
        ],
      ),
    );
  }
}
