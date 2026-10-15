import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/core/format/formato_moneda.dart';
import 'package:inkash/features/tipo_cambio/domain/tipo_cambio.dart';
import 'package:inkash/features/tipo_cambio/presentation/tipo_cambio_provider.dart';
import 'package:inkash/theme.dart';

// Tarjeta "Dólar hoy". Los mismos 3 estados que el dashboard, en pequeño.
class TipoCambioCard extends ConsumerWidget {
  const TipoCambioCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tipoCambio = ref.watch(tipoCambioProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kSuperficie,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: kBorde),
      ),
      child: Row(
        children: [
          const Icon(Icons.currency_exchange, color: kLima, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: tipoCambio.when(
              loading: () => const Text(
                'Consultando el dólar…',
                style: TextStyle(color: kMuted),
              ),
              error: (error, _) => Text(
                error is TipoCambioException
                    ? 'Dólar no disponible: ${error.mensaje}'
                    : 'Dólar no disponible.',
                style: const TextStyle(color: kMuted, fontSize: 12),
              ),
              data: (tc) => _Tasa(tipoCambio: tc),
            ),
          ),
          IconButton(
            tooltip: 'Actualizar tipo de cambio',
            onPressed: tipoCambio.isLoading
                ? null
                : () => ref.invalidate(tipoCambioProvider),
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
    );
  }
}

class _Tasa extends StatelessWidget {
  const _Tasa({required this.tipoCambio});

  final TipoCambio tipoCambio;

  @override
  Widget build(BuildContext context) {
    final hora = TimeOfDay.fromDateTime(tipoCambio.actualizado).format(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dólar hoy · ${formatQuetzales(tipoCambio.centavosPorDolar)}'),
        Text(
          // Honestidad con el usuario: decir cuando el dato es viejo.
          tipoCambio.desdeCache
              ? 'Sin conexión · último dato ${_fecha(tipoCambio.actualizado)} $hora'
              : 'Actualizado $hora',
          style: TextStyle(
            fontSize: 11,
            color: tipoCambio.desdeCache ? kPeligro : kMuted,
          ),
        ),
      ],
    );
  }

  String _fecha(DateTime f) => '${f.day}/${f.month}';
}
