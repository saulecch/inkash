import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/features/cuentas/data/cuentas_repository.dart';
import 'package:inkash/features/cuentas/domain/cuenta.dart';

final cuentasRepositoryProvider = Provider<CuentasRepository>(
  (ref) => CuentasRepository(),
);

// Lo usan la tarjeta "Cuentas" del Inicio y el formulario (selector).
final cuentasProvider = FutureProvider<List<Cuenta>>(
  (ref) => ref.watch(cuentasRepositoryProvider).obtenerConSaldo(),
  retry: (_, _) => null,
);
