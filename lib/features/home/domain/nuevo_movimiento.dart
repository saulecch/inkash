// Lo que el formulario entrega para guardar. Es distinto de `Movimiento`
// (lo que se muestra en el dashboard): aquí todavía no hay id ni subtítulo.
class NuevoMovimiento {
  const NuevoMovimiento({
    required this.titulo,
    required this.montoCentavos,
    required this.esIngreso,
    required this.categoria,
    required this.fecha,
    this.cuentaId,
  }) : assert(montoCentavos > 0, 'El monto siempre llega positivo');

  final String titulo;

  // Positivo siempre. El signo se decide al guardar (ver montoFirmadoCentavos).
  final int montoCentavos;
  final bool esIngreso;
  final String categoria;
  final DateTime fecha;

  // s16-01: en qué cuenta pasó. null solo en datos de prueba.
  final int? cuentaId;

  // En SQLite el gasto se guarda negativo: así SUM(monto_centavos) = saldo.
  int get montoFirmadoCentavos => esIngreso ? montoCentavos : -montoCentavos;
}

// Categorías que ofrece el formulario y el nombre del icono que se guarda
// en la tabla `categorias` (texto, porque SQLite no sabe qué es un IconData).
const categoriasBase = <String, String>{
  'Transporte': 'directions_bus',
  'Súper y comida': 'shopping_cart',
  'Ingreso': 'arrow_upward',
  'Entretenimiento': 'movie',
  'Servicios': 'bolt',
  'Hogar': 'home',
};
