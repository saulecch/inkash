import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/core/format/formato_moneda.dart';
import 'package:inkash/features/home/domain/movimiento.dart';
import 'package:inkash/features/home/presentation/controllers/home_controller.dart';
import 'package:inkash/theme.dart';
import 'package:inkash/features/home/presentation/widgets/movimiento_bottom_sheet.dart';

// ConsumerWidget = StatelessWidget + acceso a `ref`.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch: cuando el estado cambie, este build se vuelve a ejecutar.
    final resumen = ref.watch(homeControllerProvider);

    return Scaffold(
      body: SafeArea(
        // Los estados de una consulta asíncrona, explícitos y sin if anidados.
        // Al recargar (tras guardar) se siguen viendo los datos anteriores.
        child: resumen.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorCarga(
            onReintentar: () => ref.invalidate(homeControllerProvider),
          ),
          data: (resumen) => _dashboard(resumen),
        ),
      ),
      bottomNavigationBar: _barraInferior(context, ref),
    );
  }

  Widget _dashboard(ResumenHome resumen) {
    final totalGastado = resumen.totalGastadoCentavos;
    final saldoDisponible = resumen.saldoDisponibleCentavos;
    final movimientos = resumen.movimientos;

    return ListView(
      padding: EdgeInsets.all(16.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Hola, Kevin'),
            Text('Julio 2026', style: TextStyle(color: kMuted)),
          ],
        ),
        const SizedBox(height: 22),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'TE QUEDAN DISPONIBLES',
              style: TextStyle(fontSize: 11, color: kLima),
            ),
            Text(
              formatQuetzales(saldoDisponible),
              style: const TextStyle(
                fontSize: 52,
                color: kTexto,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              // clamp: si gastó más del límite, la barra no se desborda.
              value: (totalGastado / resumen.limiteMensualCentavos).clamp(0, 1),
              color: kLima,
              minHeight: 8.0,
            ),
            const SizedBox(height: 7),
            Text(
              'Has usado ${formatQuetzales(totalGastado)} '
              'de ${formatQuetzales(resumen.limiteMensualCentavos)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            tarjetaHero('Cuentas', 'Q7,810.00'),
            const SizedBox(width: 12),
            tarjetaHero('Metas de ahorro', '3 activas'),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Text('Últimos movimientos', style: TextStyle(fontSize: 20)),
            Spacer(),
            TextButton(
              onPressed: () {},
              child: Text(
                'Ver todo',
                style: TextStyle(fontSize: 13, color: kLima),
              ),
            ),
          ],
        ),
        // Estado vacío: también es un estado que hay que diseñar.
        if (movimientos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'Aún no hay movimientos.\nToca + para registrar el primero.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kMuted),
            ),
          ),
        ...movimientos.map(filaMovimiento),
      ],
    );
  }

  Widget _barraInferior(BuildContext context, WidgetRef ref) {
    return BottomNavigationBar(
      currentIndex: 0,
      onTap: (index) async {
        // Para que funcione solo en el boton de + o agregar.
        if (index != 2) return;
        // El sheet devuelve true con Navigator.pop(true) si guardó.
        final guardado = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          showDragHandle: true,
          backgroundColor: kSuperficie,
          // read (no watch): en un callback solo queremos llamar un método.
          builder: (context) => MovimientoBottomSheet(
            onGuardar: ref
                .read(homeControllerProvider.notifier)
                .guardarMovimiento,
          ),
        );
        if (guardado != true || !context.mounted) return;
        // s14-02: el controlador ya recargó desde SQLite; la lista se
        // actualiza sola porque HomePage hace ref.watch.
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Movimiento guardado')));
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: kLima,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Presupuesto',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle, size: 34),
          label: 'Agregar',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Historial'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
      ],
    );
  }

  Widget filaMovimiento(Movimiento movimiento) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: kIconoFondo,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(_iconDataDe(movimiento.icono), color: kLima),
      ),
      title: Text(movimiento.titulo, style: TextStyle(color: kTexto)),
      subtitle: Text(movimiento.subtitulo, style: TextStyle(color: kMuted)),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatQuetzales(movimiento.montoFirmadoCentavos),
            style: TextStyle(
              fontSize: 13,
              color: movimiento.esIngreso ? kLima : kTexto,
            ),
          ),
          Text(movimiento.fecha, style: TextStyle(fontSize: 10, color: kMuted)),
        ],
      ),
    );
  }

  // Convierte el nombre del icono (guardado como texto) a un IconData.
  IconData _iconDataDe(String nombre) {
    return switch (nombre) {
      'directions_bus' => Icons.directions_bus,
      'shopping_cart' => Icons.shopping_cart,
      'arrow_upward' => Icons.arrow_upward,
      'local_cafe' => Icons.local_cafe,
      'movie' => Icons.movie_outlined,
      'bolt' => Icons.bolt,
      'home' => Icons.home,
      _ => Icons.attach_money,
    };
  }

  Widget tarjetaHero(String title, String body) {
    return Expanded(
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
            Text(title, style: TextStyle(fontSize: 11, color: kMuted)),
            SizedBox(height: 2),
            Text(body, style: TextStyle(fontSize: 19)),
          ],
        ),
      ),
    );
  }
}

// Estado de error: mensaje humano + una acción. Nunca un stack trace.
class _ErrorCarga extends StatelessWidget {
  const _ErrorCarga({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: kPeligro, size: 40),
            const SizedBox(height: 12),
            const Text(
              'No pudimos leer tus movimientos.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
