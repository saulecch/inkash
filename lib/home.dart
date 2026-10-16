import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/core/format/formato_fecha.dart';
import 'package:inkash/core/format/formato_moneda.dart';
import 'package:inkash/features/home/presentation/controllers/home_controller.dart';
import 'package:inkash/features/home/presentation/widgets/movimiento_tile.dart';
import 'package:inkash/features/navegacion/navegacion_controller.dart';
import 'package:inkash/features/tipo_cambio/presentation/tipo_cambio_card.dart';
import 'package:inkash/theme.dart';

// ConsumerWidget = StatelessWidget + acceso a `ref`.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch: cuando el estado cambie, este build se vuelve a ejecutar.
    final resumen = ref.watch(homeControllerProvider);

    // s15-01: ya no es un Scaffold. La barra inferior vive en InkashShell.
    return SafeArea(
      // Los estados de una consulta asíncrona, explícitos y sin if anidados.
      // Al recargar (tras guardar) se siguen viendo los datos anteriores.
      child: resumen.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorCarga(
          onReintentar: () => ref.invalidate(homeControllerProvider),
        ),
        data: (resumen) => _dashboard(resumen, ref),
      ),
    );
  }

  Widget _dashboard(ResumenHome resumen, WidgetRef ref) {
    final totalGastado = resumen.totalGastadoCentavos;
    final saldoDisponible = resumen.saldoDisponibleCentavos;
    final movimientos = resumen.ultimosMovimientos;

    return ListView(
      padding: EdgeInsets.all(16.0),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Hola, Kevin'),
            // s15-02: el mes real, no 'Julio 2026' escrito a mano.
            Text(nombreMes(resumen.mes), style: TextStyle(color: kMuted)),
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
        const SizedBox(height: 12),
        // S14-03: dato remoto. Si falla, el resto del dashboard sigue vivo:
        // cada provider tiene su propio estado de carga y error.
        const TipoCambioCard(),
        const SizedBox(height: 28),
        Row(
          children: [
            Text('Últimos movimientos', style: TextStyle(fontSize: 20)),
            Spacer(),
            TextButton(
              // Navegar = cambiar el estado de la pestaña activa.
              onPressed: () =>
                  ref.read(navegacionProvider.notifier).ir(Pestana.historial),
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
        for (final movimiento in movimientos)
          MovimientoTile(movimiento: movimiento),
      ],
    );
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
