// Totales de un mes, ya sumados por SQLite (no en Dart).
class TotalesMes {
  const TotalesMes({
    required this.gastosCentavos,
    required this.ingresosCentavos,
  });

  static const cero = TotalesMes(gastosCentavos: 0, ingresosCentavos: 0);

  // Ambos positivos: el signo es cosa de la base de datos.
  final int gastosCentavos;
  final int ingresosCentavos;
}
