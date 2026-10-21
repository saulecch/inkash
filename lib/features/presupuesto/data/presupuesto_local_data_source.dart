import 'package:inkash/core/database/app_database.dart';
import 'package:inkash/core/format/formato_fecha.dart';
import 'package:inkash/features/presupuesto/domain/presupuesto_categoria.dart';
import 'package:sqflite/sqflite.dart';

class PresupuestoLocalDataSource {
  PresupuestoLocalDataSource({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  // Todas las categorías de gasto, con su límite (si tiene) y lo gastado
  // en el mes.
  //
  // OJO, la idea de la clase: el filtro del mes va en el ON del LEFT JOIN,
  // NO en el WHERE. En el WHERE, "m.fecha >= ?" descarta las filas donde m es
  // NULL... y las categorías sin gastos este mes desaparecerían de la lista.
  Future<List<PresupuestoCategoria>> obtenerDelMes(DateTime mes) async {
    final db = await _database.database;
    final filas = await db.rawQuery(
      '''
      SELECT c.id, c.nombre, c.icono, p.limite_centavos,
             COALESCE(SUM(-m.monto_centavos), 0) AS gastado
      FROM categorias c
      LEFT JOIN presupuestos p ON p.categoria_id = c.id
      LEFT JOIN movimientos m ON m.categoria_id = c.id
        AND m.monto_centavos < 0
        AND m.fecha >= ? AND m.fecha < ?
      WHERE c.tipo = 'gasto' AND c.archivada = 0
      GROUP BY c.id
      ORDER BY p.limite_centavos IS NULL, c.nombre
      ''',
      [
        inicioDeMes(mes).millisecondsSinceEpoch,
        inicioMesSiguiente(mes).millisecondsSinceEpoch,
      ],
    );
    return [
      for (final f in filas)
        PresupuestoCategoria(
          categoriaId: f['id']! as int,
          nombre: f['nombre']! as String,
          icono: f['icono']! as String,
          limiteCentavos: f['limite_centavos'] as int?,
          gastadoCentavos: f['gastado']! as int,
        ),
    ];
  }

  // null quita el límite. "Upsert": si ya hay fila, REPLACE la sustituye.
  Future<void> definirLimite(int categoriaId, int? limiteCentavos) async {
    final db = await _database.database;
    if (limiteCentavos == null) {
      await db.delete(
        'presupuestos',
        where: 'categoria_id = ?',
        whereArgs: [categoriaId],
      );
      return;
    }
    await db.insert('presupuestos', {
      'categoria_id': categoriaId,
      'limite_centavos': limiteCentavos,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}
