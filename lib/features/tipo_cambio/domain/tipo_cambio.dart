// Cuántos quetzales vale un dólar.
//
// La tasa trae 4 decimales (7.6543), así que la guardamos como ENTERO en
// diezmilésimas (76543): misma regla que el dinero en centavos.
class TipoCambio {
  const TipoCambio({
    required this.quetzalesPorDolarDiezmilesimas,
    required this.actualizado,
    this.desdeCache = false,
  });

  final int quetzalesPorDolarDiezmilesimas;
  final DateTime actualizado;

  // true = no hubo red y mostramos el último dato guardado.
  final bool desdeCache;

  // Para mostrar con formatQuetzales: 76543 -> 765 centavos -> 'Q7.65'.
  int get centavosPorDolar => (quetzalesPorDolarDiezmilesimas / 100).round();
}

// Error con mensaje para humanos. La UI nunca muestra un stack trace.
class TipoCambioException implements Exception {
  const TipoCambioException(this.mensaje);

  final String mensaje;

  @override
  String toString() => 'TipoCambioException: $mensaje';
}
