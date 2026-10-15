import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:inkash/features/tipo_cambio/domain/tipo_cambio.dart';

// Fuente de datos REMOTA. Es la única clase que sabe de HTTP y JSON.
// API pública y gratuita, sin API key: https://www.exchangerate-api.com/docs/free
class TipoCambioApi {
  // El cliente se inyecta: en las pruebas usamos MockClient (sin internet).
  TipoCambioApi({
    http.Client? client,
    this.timeout = const Duration(seconds: 5),
  }) : _client = client ?? http.Client();

  static final _url = Uri.parse('https://open.er-api.com/v6/latest/USD');

  final http.Client _client;
  final Duration timeout;

  // Convierte CADA forma de fallar en un TipoCambioException con un mensaje
  // claro. Hay 4 formas distintas de fallar y las 4 pasan en la vida real.
  Future<int> obtenerQuetzalesPorDolar() async {
    final http.Response respuesta;
    try {
      // Sin timeout, una red lenta deja la app "cargando" para siempre.
      respuesta = await _client.get(_url).timeout(timeout);
    } on TimeoutException {
      throw const TipoCambioException('El servidor tardó demasiado.');
    } on http.ClientException {
      // 1. Sin internet, DNS caído, modo avión...
      throw const TipoCambioException('Sin conexión a internet.');
    }

    // 2. El servidor respondió, pero con error (404, 429, 500...).
    if (respuesta.statusCode != 200) {
      throw TipoCambioException(
        'El servidor respondió ${respuesta.statusCode}.',
      );
    }

    // 3. Respondió 200 pero el JSON no trae lo que esperamos.
    try {
      final json = jsonDecode(respuesta.body) as Map<String, dynamic>;
      final tasas = json['rates'] as Map<String, dynamic>;
      final gtq = tasas['GTQ'] as num;
      // Aquí sí aparece un double (viene así del JSON); lo convertimos a
      // entero UNA vez, en la frontera, y el resto de la app usa enteros.
      return (gtq * 10000).round();
    } catch (_) {
      throw const TipoCambioException('Respuesta inesperada del servidor.');
    }
  }
}
