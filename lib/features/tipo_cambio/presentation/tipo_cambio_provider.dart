import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/features/tipo_cambio/data/tipo_cambio_repository.dart';
import 'package:inkash/features/tipo_cambio/domain/tipo_cambio.dart';

final tipoCambioRepositoryProvider = Provider<TipoCambioRepository>((ref) {
  return TipoCambioRepository();
});

// FutureProvider: no hay métodos que llamar (solo leer), así que no hace
// falta un AsyncNotifier. Para recargar: ref.invalidate(tipoCambioProvider).
final tipoCambioProvider = FutureProvider<TipoCambio>(
  (ref) => ref.watch(tipoCambioRepositoryProvider).obtener(),
  retry: (_, _) => null,
);
