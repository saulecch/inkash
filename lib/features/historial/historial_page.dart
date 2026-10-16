import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/core/format/formato_fecha.dart';
import 'package:inkash/core/format/formato_moneda.dart';
import 'package:inkash/features/historial/historial_controller.dart';
import 'package:inkash/features/home/domain/movimiento.dart';
import 'package:inkash/features/home/presentation/controllers/home_controller.dart';
import 'package:inkash/features/home/presentation/widgets/movimiento_tile.dart';
import 'package:inkash/theme.dart';

class HistorialPage extends ConsumerWidget {
  const HistorialPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(filtroHistorialProvider);
    final controller = ref.read(filtroHistorialProvider.notifier);
    final movimientos = ref.watch(historialProvider);

    return SafeArea(
      child: Column(
        children: [
          // Selector de mes: ‹ Octubre 2026 ›
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Mes anterior',
                  onPressed: controller.mesAnterior,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    nombreMes(filtro.mes),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                IconButton(
                  tooltip: 'Mes siguiente',
                  onPressed: controller.mesSiguiente,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          _ChipsCategoria(seleccionada: filtro.categoria),
          Expanded(
            // skipLoadingOnRefresh: false -> al cambiar el filtro se ve el
            // indicador de carga en vez de la lista del filtro anterior.
            child: movimientos.when(
              skipLoadingOnRefresh: false,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No pudimos leer el historial.'),
                    TextButton(
                      onPressed: () => ref.invalidate(historialProvider),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
              data: (lista) => lista.isEmpty
                  ? const Center(
                      child: Text(
                        'Sin movimientos en este mes.',
                        style: TextStyle(color: kMuted),
                      ),
                    )
                  : _ListaAgrupada(movimientos: lista),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipsCategoria extends ConsumerWidget {
  const _ChipsCategoria({required this.seleccionada});

  final String? seleccionada;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si las categorías fallan o cargan, mostramos solo "Todas":
    // un filtro no debe tumbar la pantalla.
    final categorias = ref.watch(categoriasUsadasProvider).value ?? const [];
    final controller = ref.read(filtroHistorialProvider.notifier);

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final nombre in [null, ...categorias])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(nombre ?? 'Todas'),
                selected: seleccionada == nombre,
                onSelected: (_) => controller.categoria(nombre),
              ),
            ),
        ],
      ),
    );
  }
}

// Lista con encabezado por día y el total del mes filtrado arriba.
class _ListaAgrupada extends StatelessWidget {
  const _ListaAgrupada({required this.movimientos});

  final List<Movimiento> movimientos;

  @override
  Widget build(BuildContext context) {
    // Aquí sí sumamos en Dart: la lista ya está en memoria y filtrada.
    var gastos = 0;
    var ingresos = 0;
    for (final m in movimientos) {
      m.esIngreso ? ingresos += m.montoCentavos : gastos += m.montoCentavos;
    }

    final filas = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Text(
          'Gastos ${formatQuetzales(gastos)} · '
          'Ingresos ${formatQuetzales(ingresos)}',
          style: const TextStyle(color: kMuted, fontSize: 12),
        ),
      ),
    ];
    DateTime? diaAnterior;
    for (final m in movimientos) {
      final dia = DateUtils.dateOnly(m.fechaHora);
      // Como vienen ordenados por fecha, basta comparar con el anterior.
      if (dia != diaAnterior) {
        filas.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              m.fecha,
              style: const TextStyle(color: kLima, fontSize: 12),
            ),
          ),
        );
        diaAnterior = dia;
      }
      filas.add(_Deslizable(movimiento: m));
    }
    return ListView(children: filas);
  }
}

// s15-04: deslizar a la izquierda para borrar, con "Deshacer".
class _Deslizable extends ConsumerWidget {
  const _Deslizable({required this.movimiento});

  final Movimiento movimiento;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      // La key debe ser el id: si fuera el índice, Flutter confundiría filas.
      key: ValueKey(movimiento.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: kPeligro.withValues(alpha: .25),
        child: const Icon(Icons.delete_outline, color: kPeligro),
      ),
      // confirmDismiss: primero borramos en SQLite. Si falla, devolvemos
      // false y la fila regresa a su lugar (no "desaparece" en falso).
      confirmDismiss: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        final controller = ref.read(homeControllerProvider.notifier);
        try {
          final eliminado = await controller.eliminar(movimiento.id);
          messenger.showSnackBar(
            SnackBar(
              content: Text('"${movimiento.titulo}" eliminado'),
              action: eliminado == null
                  ? null
                  : SnackBarAction(
                      label: 'Deshacer',
                      onPressed: () => controller.deshacer(eliminado),
                    ),
            ),
          );
          return true;
        } catch (_) {
          messenger.showSnackBar(
            const SnackBar(content: Text('No se pudo eliminar.')),
          );
          return false;
        }
      },
      child: MovimientoTile(movimiento: movimiento),
    );
  }
}
