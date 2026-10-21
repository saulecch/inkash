import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/core/format/formato_fecha.dart';
import 'package:inkash/core/format/formato_moneda.dart';
import 'package:inkash/core/ui/estado_vacio.dart';
import 'package:inkash/core/ui/monto.dart';
import 'package:inkash/features/home/presentation/controllers/home_controller.dart';
import 'package:inkash/features/cuentas/presentation/tarjeta_cuentas.dart';
import 'package:inkash/features/home/presentation/widgets/abrir_formulario_movimiento.dart';
import 'package:inkash/features/home/presentation/widgets/movimiento_tile.dart';
import 'package:inkash/features/metas/presentation/tarjeta_metas.dart';
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
        data: (resumen) => _dashboard(context, resumen, ref),
      ),
    );
  }

  Widget _dashboard(BuildContext context, ResumenHome resumen, WidgetRef ref) {
    final texto = Theme.of(context).textTheme;
    final totalGastado = resumen.totalGastadoCentavos;
    final saldoDisponible = resumen.saldoDisponibleCentavos;
    final movimientos = resumen.ultimosMovimientos;
    final excedido = saldoDisponible < 0;

    // s17-01: todos los espacios y estilos salen de los tokens del tema.
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Espacio.l,
        Espacio.xl,
        Espacio.l,
        Espacio.xxl,
      ),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Hola, Kevin', style: texto.titleMedium),
            // s15-02: el mes real, no 'Julio 2026' escrito a mano.
            Text(nombreMes(resumen.mes), style: texto.bodySmall),
          ],
        ),
        const SizedBox(height: Espacio.xxl),
        // Lo más importante de la app, en una frase y sin mayúsculas
        // sostenidas: cuánto queda del mes.
        Text(
          excedido ? 'Te pasaste del límite por' : 'Te quedan este mes',
          style: texto.bodyMedium?.copyWith(color: excedido ? kPeligro : kLima),
        ),
        const SizedBox(height: Espacio.xs),
        Monto(
          saldoDisponible.abs(),
          estilo: texto.displayLarge?.copyWith(
            color: excedido ? kPeligro : kTexto,
          ),
        ),
        const SizedBox(height: Espacio.l),
        ClipRRect(
          borderRadius: BorderRadius.circular(Espacio.xs),
          child: LinearProgressIndicator(
            // clamp: si gastó más del límite, la barra no se desborda.
            value: (totalGastado / resumen.limiteMensualCentavos).clamp(0, 1),
            color: excedido ? kPeligro : kLima,
            minHeight: Espacio.s,
          ),
        ),
        const SizedBox(height: Espacio.s),
        Text(
          'Has usado ${formatQuetzales(totalGastado)} '
          'de ${formatQuetzales(resumen.limiteMensualCentavos)}',
          style: texto.bodySmall,
        ),
        const SizedBox(height: Espacio.xl),
        const Row(
          children: [
            TarjetaCuentas(), // s16-01: datos reales
            SizedBox(width: Espacio.m),
            TarjetaMetas(), // s16-05: datos reales
          ],
        ),
        const SizedBox(height: Espacio.m),
        // S14-03: dato remoto. Si falla, el resto del dashboard sigue vivo:
        // cada provider tiene su propio estado de carga y error.
        const TipoCambioCard(),
        const SizedBox(height: Espacio.xl),
        Row(
          children: [
            Expanded(
              child: Text('Últimos movimientos', style: texto.titleLarge),
            ),
            TextButton(
              // Navegar = cambiar el estado de la pestaña activa.
              onPressed: () =>
                  ref.read(navegacionProvider.notifier).ir(Pestana.historial),
              child: const Text('Ver todo'),
            ),
          ],
        ),
        // Estado vacío: una invitación con su acción, no solo un texto.
        if (movimientos.isEmpty)
          EstadoVacio(
            icono: Icons.receipt_long_outlined,
            titulo: 'Aún no hay movimientos',
            mensaje: 'Registra tu primer gasto o ingreso del mes.',
            accion: 'Registrar movimiento',
            onAccion: () => abrirFormularioMovimiento(context, ref),
          ),
        for (final movimiento in movimientos)
          MovimientoTile(
            movimiento: movimiento,
            onTap: () =>
                abrirFormularioMovimiento(context, ref, editar: movimiento),
          ),
      ],
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
