import 'package:riverpod/riverpod.dart';

// Riverpod sabe cómo construir y entregar el controlador.
final movimientosControllerProvider = Provider<MovimientosController>((ref) {
  return MovimientosController();
});

class MovimientosController {
  MovimientosController()
    : gastosCentavos = const [
        3800, // Uber
        28550, // Supermercado
        6500, // Café
        42000, // Electricidad
        289500, // Vivienda y gastos anteriores
      ];

  // El dinero se guarda como centavos para evitar errores de decimales.
  final int limiteMensualCentavos = 650000;

  // Por ahora los datos viven solamente en memoria.
  final List<int> gastosCentavos;

  // El total siempre se calcula a partir de la lista.
  int get totalGastadoCentavos {
    return gastosCentavos.fold(0, (total, gasto) => total + gasto);
  }

  // El saldo se deriva del límite y del total calculado.
  int get saldoDisponibleCentavos {
    return limiteMensualCentavos - totalGastadoCentavos;
  }
}
