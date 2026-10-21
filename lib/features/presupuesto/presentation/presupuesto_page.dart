import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/core/format/formato_fecha.dart';
import 'package:inkash/core/format/formato_moneda.dart';
import 'package:inkash/core/reloj.dart';
import 'package:inkash/core/ui/encabezado_pagina.dart';
import 'package:inkash/core/ui/seccion.dart';
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
          padding: const EdgeInsets.only(bottom: Espacio.xxl),
          children: [
            EncabezadoPagina(titulo: 'Presupuesto', subtitulo: nombreMes(mes)),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Espacio.l,
                0,
                Espacio.l,
                Espacio.xl,
              ),
              child: _Resumen(filas: filas),
            ),
            Seccion(
              titulo: 'Toca una categoría para definir su límite mensual',
              children: [
                for (final fila in filas)
                  _FilaPresupuesto(
                    fila: fila,
                    onTap: () => _editarLimite(context, ref, fila),
                  ),
              ],
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
      leading: Icon(iconoDe(fila.icono), color: kLima),
      title: Text(fila.nombre),
      trailing: const Icon(Icons.chevron_right),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Espacio.s),
          if (fila.progreso != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(Espacio.xs),
              child: LinearProgressIndicator(
                value: fila.progreso,
                minHeight: 6,
                color: fila.excedido ? kPeligro : kLima,
              ),
            ),
          const SizedBox(height: Espacio.xs),
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
      return Text(
        'Aún no tienes límites. Empieza por la categoría donde más gastas.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: kMuted),
      );
    }
    final limite = conLimite.fold(0, (t, f) => t + f.limiteCentavos!);
    final gastado = conLimite.fold(0, (t, f) => t + f.gastadoCentavos);
    final excedidas = conLimite.where((f) => f.excedido).length;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Espacio.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              gastado > limite
                  ? 'Te pasaste por ${formatQuetzales(gastado - limite)}'
                  : 'Te quedan ${formatQuetzales(limite - gastado)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontFeatures: kNumerosTabulares,
                color: gastado > limite ? kPeligro : kTexto,
              ),
            ),
            const SizedBox(height: Espacio.xs),
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
      ),
    );
  }
}
