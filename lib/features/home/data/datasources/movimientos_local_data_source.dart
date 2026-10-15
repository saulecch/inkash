import 'package:inkash/core/database/app_database.dart';
import 'package:inkash/features/home/domain/movimiento.dart';
import 'package:inkash/features/home/domain/nuevo_movimiento.dart';
import 'package:sqflite/sqflite.dart';

// Fuente de datos local. Es la ÚNICA clase que conoce SQL.
// s14-01: ya ESCRIBE en SQLite; la lectura sigue en memoria (s14-02 la cambia).
class MovimientosLocalDataSource {
  // La base se inyecta para poder usar una base temporal en las pruebas.
  MovimientosLocalDataSource({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  // Guarda un movimiento. Categoría + movimiento van en UNA transacción:
  // si falla el INSERT del movimiento, tampoco queda una categoría huérfana.
  Future<void> insertar(NuevoMovimiento nuevo) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      final categoriaId = await _obtenerOCrearCategoria(txn, nuevo.categoria);
      await txn.insert('movimientos', {
        // Sin paquete uuid: microsegundos alcanzan para una app de un usuario.
        'id': DateTime.now().microsecondsSinceEpoch.toString(),
        'titulo': nuevo.titulo,
        'monto_centavos': nuevo.montoFirmadoCentavos,
        // La fecha viaja como entero (epoch en ms): ordenable y sin zona.
        'fecha': nuevo.fecha.millisecondsSinceEpoch,
        'categoria_id': categoriaId,
      });
    });
  }

  // La tabla `categorias` empieza vacía: se crea la fila la primera vez que
  // se usa. `nombre` es UNIQUE, así que nunca habrá dos "Transporte".
  Future<int> _obtenerOCrearCategoria(Transaction txn, String nombre) async {
    final filas = await txn.query(
      'categorias',
      columns: ['id'],
      where: 'nombre = ?', // Siempre con ?, nunca concatenando texto (SQLi).
      whereArgs: [nombre],
    );
    if (filas.isNotEmpty) return filas.single['id']! as int;

    return txn.insert('categorias', {
      'nombre': nombre,
      'icono': categoriasBase[nombre] ?? 'attach_money',
    });
  }

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
