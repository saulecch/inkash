// Entidad de dominio que representa un movimiento financiero.
class Movimiento {
  const Movimiento({
    required this.id,
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.montoCentavos,
    required this.fecha,
    required this.fechaHora,
    this.esIngreso = false,
  });

  final String id;
  final String titulo;
  final String subtitulo;
  final String icono;
  // `fecha` es la etiqueta corta ('Hoy', 'Ayer'); `fechaHora` el instante
  // real. s15-03: el Historial agrupa por día, así que necesita el instante.
  final String fecha;
  final DateTime fechaHora;
  final bool esIngreso;

  // El monto se guarda en centavos (entero) para evitar errores de decimales.
  final int montoCentavos;

  // El monto en centavos siempre es positivo; el signo depende de esIngreso.
  int get montoFirmadoCentavos => esIngreso ? montoCentavos : -montoCentavos;
}
