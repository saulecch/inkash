import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/core/format/formato_fecha.dart';
import 'package:inkash/core/reloj.dart';
import 'package:inkash/features/home/domain/movimiento.dart';
import 'package:inkash/features/home/presentation/controllers/home_controller.dart';

// Qué quiere ver el usuario. Inmutable: cambiar el filtro = crear uno nuevo.
class FiltroHistorial {
  const FiltroHistorial({required this.mes, this.categoria});

  final DateTime mes; // siempre el día 1 del mes
  final String? categoria; // null = todas

  FiltroHistorial copyWith({DateTime? mes, String? Function()? categoria}) {
    return FiltroHistorial(
      mes: mes ?? this.mes,
      // Función para poder pasar null a propósito ("Todas").
      categoria: categoria == null ? this.categoria : categoria(),
    );
  }
}

final filtroHistorialProvider =
    NotifierProvider<FiltroHistorialController, FiltroHistorial>(
      FiltroHistorialController.new,
    );

class FiltroHistorialController extends Notifier<FiltroHistorial> {
  @override
  FiltroHistorial build() =>
      FiltroHistorial(mes: inicioDeMes(ref.read(relojProvider)()));

  void mesAnterior() => state = state.copyWith(
    mes: DateTime(state.mes.year, state.mes.month - 1),
  );

  void mesSiguiente() => state = state.copyWith(
    mes: DateTime(state.mes.year, state.mes.month + 1),
  );

  void categoria(String? nombre) =>
      state = state.copyWith(categoria: () => nombre);
}

// LA IDEA DE LA CLASE: un provider que depende de otro.
// Este FutureProvider hace ref.watch del filtro; cuando el filtro cambia,
// Riverpod lo vuelve a ejecutar solo. No hay "if cambió, recargar".
final historialProvider = FutureProvider<List<Movimiento>>((ref) {
  final filtro = ref.watch(filtroHistorialProvider);
  return ref
      .watch(movimientosRepositoryProvider)
      .obtenerMovimientos(mes: filtro.mes, categoria: filtro.categoria);
}, retry: (_, _) => null);

final categoriasUsadasProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(movimientosRepositoryProvider).obtenerCategoriasUsadas(),
  retry: (_, _) => null,
);
