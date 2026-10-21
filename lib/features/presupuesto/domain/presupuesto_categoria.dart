// Una fila de la pestaña Presupuesto: cuánto se puede y cuánto se lleva.
class PresupuestoCategoria {
  const PresupuestoCategoria({
    required this.categoriaId,
    required this.nombre,
    required this.icono,
    required this.gastadoCentavos,
    this.limiteCentavos,
  });

  final int categoriaId;
  final String nombre;
  final String icono;
  final int gastadoCentavos;
  final int? limiteCentavos; // null = sin límite definido

  bool get excedido =>
      limiteCentavos != null && gastadoCentavos > limiteCentavos!;

  // 0..1 para la barra. Aquí un double está bien: es para dibujar, no dinero.
  double? get progreso => limiteCentavos == null
      ? null
      : (gastadoCentavos / limiteCentavos!).clamp(0, 1).toDouble();
}
