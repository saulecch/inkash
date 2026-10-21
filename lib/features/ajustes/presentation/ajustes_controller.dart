import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/features/ajustes/data/ajustes_repository.dart';
import 'package:inkash/features/ajustes/domain/ajustes.dart';
import 'package:inkash/features/cuentas/domain/cuenta.dart';
import 'package:inkash/features/cuentas/presentation/cuentas_provider.dart';
import 'package:inkash/features/historial/historial_controller.dart';
import 'package:inkash/features/metas/presentation/metas_provider.dart';
import 'package:inkash/features/presupuesto/presentation/presupuesto_provider.dart';
import 'package:inkash/features/tipo_cambio/presentation/tipo_cambio_provider.dart';

final ajustesRepositoryProvider = Provider<AjustesRepository>(
  (ref) => AjustesRepository(),
);

// El Inicio hace ref.watch de este provider: cambiar el límite en Ajustes
// recalcula el saldo del Inicio SIN que Ajustes sepa que el Inicio existe.
final ajustesProvider = AsyncNotifierProvider<AjustesController, Ajustes>(
  AjustesController.new,
  retry: (_, _) => null,
);

class AjustesController extends AsyncNotifier<Ajustes> {
  AjustesRepository get _repo => ref.read(ajustesRepositoryProvider);

  @override
  Future<Ajustes> build() => _repo.leer();

  Future<void> cambiarNombre(String nombre) async {
    await _repo.guardarNombre(nombre);
    ref.invalidateSelf();
    await future;
  }

  Future<void> cambiarLimite(int centavos) async {
    await _repo.guardarLimite(centavos);
    ref.invalidateSelf();
    await future;
  }

  // s17-03: lo que se contesta en la bienvenida se guarda con los MISMOS
  // repositorios que usan Ajustes y Cuentas: la bienvenida no tiene datos
  // propios, solo es otra forma de llegar a ellos.
  Future<void> completarBienvenida({
    required String nombre,
    required int limiteMensualCentavos,
    required List<(Cuenta, int)> saldosIniciales,
  }) async {
    if (nombre.trim().isNotEmpty) await _repo.guardarNombre(nombre);
    await _repo.guardarLimite(limiteMensualCentavos);
    final cuentas = ref.read(cuentasRepositoryProvider);
    for (final (cuenta, saldo) in saldosIniciales) {
      await cuentas.guardar(
        id: cuenta.id,
        nombre: cuenta.nombre,
        icono: cuenta.icono,
        saldoInicialCentavos: saldo,
      );
    }
    await _repo.marcarBienvenidaCompleta();
    ref.invalidate(cuentasProvider);
    ref.invalidateSelf();
    await future;
  }

  Future<void> borrarDatosDelUsuario() async {
    await _repo.borrarDatosDelUsuario();
    // Todo lo que lee las tablas borradas debe volver a leer. La lista es
    // explícita a propósito: si mañana se agrega una pantalla, hay que
    // decidir aquí si sus datos son "del usuario".
    // El Inicio NO se invalida aquí: hace watch de Ajustes, así que se
    // recalcula solo cuando Ajustes se invalida (y hacerlo desde aquí crea
    // una dependencia circular: Inicio -> Ajustes -> Inicio).
    ref.invalidate(historialProvider);
    ref.invalidate(categoriasUsadasProvider);
    ref.invalidate(cuentasProvider);
    ref.invalidate(presupuestoProvider);
    ref.invalidate(metasProvider);
    ref.invalidate(tipoCambioProvider);
    ref.invalidateSelf();
  }
}
