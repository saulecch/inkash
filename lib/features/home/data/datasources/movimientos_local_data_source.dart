import 'package:inkash/features/home/domain/movimiento.dart';

// Fuente de datos local. Hoy los datos viven en memoria; más adelante esta
// clase consultará la base de datos SQLite (sqflite).
class MovimientosLocalDataSource {
  // Datos de ejemplo del dashboard.
  List<Movimiento> obtenerMovimientos() {
    return const [
      Movimiento(
        id: '1',
        titulo: 'Uber al trabajo',
        subtitulo: 'Transporte · Tarjeta',
        icono: 'directions_bus',
        montoCentavos: 3800,
        fecha: 'Hoy',
      ),
      Movimiento(
        id: '2',
        titulo: 'Súper La Torre',
        subtitulo: 'Súper y comida · Tarjeta',
        icono: 'shopping_cart',
        montoCentavos: 28550,
        fecha: 'Ayer',
      ),
      Movimiento(
        id: '3',
        titulo: 'Salario quincena',
        subtitulo: 'Ingreso · Banco',
        icono: 'arrow_upward',
        montoCentavos: 420000,
        fecha: 'Ayer',
        esIngreso: true,
      ),
      Movimiento(
        id: '4',
        titulo: 'Café con Ana',
        subtitulo: 'Entretenimiento · Efectivo',
        icono: 'local_cafe',
        montoCentavos: 6500,
        fecha: 'Ayer',
      ),
      Movimiento(
        id: '5',
        titulo: 'Recibo de luz (EEGSA)',
        subtitulo: 'Servicios · Banco',
        icono: 'bolt',
        montoCentavos: 42000,
        fecha: 'Lun 20',
      ),
      Movimiento(
        id: '6',
        titulo: 'Vivienda y gastos anteriores',
        subtitulo: 'Hogar · Banco',
        icono: 'home',
        montoCentavos: 289500,
        fecha: 'Jul 15',
      ),
    ];
  }
}
