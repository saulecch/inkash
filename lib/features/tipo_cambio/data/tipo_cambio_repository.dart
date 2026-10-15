import 'package:inkash/features/tipo_cambio/data/tipo_cambio_api.dart';
import 'package:inkash/features/tipo_cambio/data/tipo_cambio_cache.dart';
import 'package:inkash/features/tipo_cambio/domain/tipo_cambio.dart';

// Offline-first "ligero": primero la red; si falla, el último dato guardado.
// La pantalla no sabe de dónde vino: solo ve TipoCambio.desdeCache.
class TipoCambioRepository {
  TipoCambioRepository({TipoCambioApi? api, TipoCambioCache? cache})
    : _api = api ?? TipoCambioApi(),
      _cache = cache ?? TipoCambioCache();

  final TipoCambioApi _api;
  final TipoCambioCache _cache;

  Future<TipoCambio> obtener() async {
    try {
      final tipoCambio = TipoCambio(
        quetzalesPorDolarDiezmilesimas: await _api.obtenerQuetzalesPorDolar(),
        actualizado: DateTime.now(),
      );
      await _cache.guardar(tipoCambio);
      return tipoCambio;
    } on TipoCambioException {
      // Sin red: si tenemos un dato anterior, mejor eso que una pantalla vacía.
      final guardado = await _cache.leer();
      if (guardado != null) return guardado;
      rethrow; // Nunca hubo dato: que la UI muestre el error.
    }
  }
}
