import 'package:inkash/core/database/app_database.dart';
import 'package:inkash/core/format/formato_fecha.dart';
import 'package:inkash/features/home/domain/movimiento.dart';
import 'package:inkash/features/home/domain/nuevo_movimiento.dart';
import 'package:sqflite/sqflite.dart';

// Fuente de datos local. Es la ÚNICA clase que conoce SQL.
// s14-02: escribe Y lee de SQLite. Los datos de ejemplo se fueron a test/.
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

  // Lee los movimientos guardados, el más reciente primero.
  // JOIN: el subtítulo y el icono viven en la tabla `categorias`.
  Future<List<Movimiento>> obtenerMovimientos({DateTime? ahora}) async {
    final db = await _database.database;
    final filas = await db.rawQuery('''
      SELECT m.id, m.titulo, m.monto_centavos, m.fecha,
             c.nombre AS categoria, c.icono
      FROM movimientos m
      JOIN categorias c ON c.id = m.categoria_id
      ORDER BY m.fecha DESC, m.id DESC
    ''');
    return filas.map((fila) => _aMovimiento(fila, ahora)).toList();
  }

  // Fila SQL (signo en el monto) -> entidad de dominio (positivo + esIngreso).
  // Este "mapeo" es justo lo que el repositorio le oculta a la pantalla.
  Movimiento _aMovimiento(Map<String, Object?> fila, DateTime? ahora) {
    final montoFirmado = fila['monto_centavos']! as int;
    final fecha = DateTime.fromMillisecondsSinceEpoch(fila['fecha']! as int);
    return Movimiento(
      id: fila['id']! as String,
      titulo: fila['titulo']! as String,
      subtitulo: fila['categoria']! as String,
      icono: fila['icono']! as String,
      montoCentavos: montoFirmado.abs(),
      esIngreso: montoFirmado > 0,
      fecha: etiquetaFecha(fecha, ahora: ahora),
    );
  }
}
