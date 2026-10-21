class Meta {
  const Meta({
    required this.id,
    required this.nombre,
    required this.objetivoCentavos,
    required this.ahorradoCentavos,
  });

  final int id;
  final String nombre;
  final int objetivoCentavos;
  final int ahorradoCentavos;

  bool get completada => ahorradoCentavos >= objetivoCentavos;

  // Para la barra (dibujar), no para dinero.
  double get progreso =>
      (ahorradoCentavos / objetivoCentavos).clamp(0, 1).toDouble();
}

// Error de negocio con mensaje para humanos (como TipoCambioException).
class MetaException implements Exception {
  const MetaException(this.mensaje);

  final String mensaje;
}
