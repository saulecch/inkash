import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/core/reloj.dart';
import 'package:inkash/features/presupuesto/data/presupuesto_repository.dart';
import 'package:inkash/features/presupuesto/domain/presupuesto_categoria.dart';

final presupuestoRepositoryProvider = Provider<PresupuestoRepository>(
  (ref) => PresupuestoRepository(),
);

final presupuestoProvider = FutureProvider<List<PresupuestoCategoria>>(
  (ref) => ref
      .watch(presupuestoRepositoryProvider)
      .obtenerDelMes(ref.watch(relojProvider)()),
  retry: (_, _) => null,
);
