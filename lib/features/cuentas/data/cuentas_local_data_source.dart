import 'package:inkash/core/database/app_database.dart';
import 'package:inkash/features/cuentas/domain/cuenta.dart';
import 'package:sqflite/sqflite.dart';

class CuentasLocalDataSource {
  CuentasLocalDataSource({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  // LEFT JOIN, no JOIN: una cuenta SIN movimientos también debe aparecer
  // (con su saldo inicial). Con JOIN "normal" desaparecería de la lista.
  // GROUP BY c.id: un SUM por cuenta.
  Future<List<Cuenta>> obtenerConSaldo() async {
    final db = await _database.database;
    final filas = await db.rawQuery('''
      SELECT c.id, c.nombre, c.icono, c.saldo_inicial_centavos,
             c.saldo_inicial_centavos + COALESCE(SUM(m.monto_centavos), 0)
               AS saldo
      FROM cuentas c
      LEFT JOIN movimientos m ON m.cuenta_id = c.id
      GROUP BY c.id
      ORDER BY c.id
    ''');
    return [
      for (final f in filas)
        Cuenta(
          id: f['id']! as int,
          nombre: f['nombre']! as String,
          icono: f['icono']! as String,
          saldoInicialCentavos: f['saldo_inicial_centavos']! as int,
          saldoCentavos: f['saldo']! as int,
        ),
    ];
  }

  // Crear y editar comparten validación: el nombre es UNIQUE en la tabla.
  Future<void> guardar({
    int? id,
    required String nombre,
    required String icono,
    required int saldoInicialCentavos,
  }) async {
    final db = await _database.database;
    final fila = {
      'nombre': nombre,
      'icono': icono,
      'saldo_inicial_centavos': saldoInicialCentavos,
    };
    try {
      if (id == null) {
        await db.insert('cuentas', fila);
      } else {
        await db.update('cuentas', fila, where: 'id = ?', whereArgs: [id]);
      }
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw CuentaException('Ya existe una cuenta llamada "$nombre".');
      }
      rethrow;
    }
  }

  // Una cuenta con movimientos NO se borra: se perdería de dónde salió el
  // dinero. Revisamos y borramos en la misma transacción.
  Future<void> eliminar(int id) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      final usados = Sqflite.firstIntValue(
        await txn.rawQuery(
          'SELECT COUNT(*) FROM movimientos WHERE cuenta_id = ?',
          [id],
        ),
      );
      if (usados! > 0) {
        throw CuentaException(
          'Tiene $usados movimientos. Muévelos o bórralos primero.',
        );
      }
      await txn.delete('cuentas', where: 'id = ?', whereArgs: [id]);
    });
  }
}
