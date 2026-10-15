import 'package:inkash/core/database/app_database.dart';
import 'package:inkash/features/tipo_cambio/domain/tipo_cambio.dart';
import 'package:sqflite/sqflite.dart';

// Fuente de datos LOCAL del tipo de cambio: el último valor que sí llegó.
// Tabla creada en la versión 2 de la base (ver onUpgrade en AppDatabase).
class TipoCambioCache {
  TipoCambioCache({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> guardar(TipoCambio tipoCambio) async {
    final db = await _database.database;
    // Una sola fila por moneda: si ya existe, se reemplaza.
    await db.insert('cache_tipo_cambio', {
      'moneda': 'USD',
      'quetzales_diezmilesimas': tipoCambio.quetzalesPorDolarDiezmilesimas,
      'actualizado_ms': tipoCambio.actualizado.millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<TipoCambio?> leer() async {
    final db = await _database.database;
    final filas = await db.query(
      'cache_tipo_cambio',
      where: 'moneda = ?',
      whereArgs: ['USD'],
    );
    if (filas.isEmpty) return null;
    final fila = filas.single;
    return TipoCambio(
      quetzalesPorDolarDiezmilesimas: fila['quetzales_diezmilesimas']! as int,
      actualizado: DateTime.fromMillisecondsSinceEpoch(
        fila['actualizado_ms']! as int,
      ),
      desdeCache: true,
    );
  }
}
