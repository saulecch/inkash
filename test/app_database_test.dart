import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkash/core/database/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  late AppDatabase database;
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inkash_database_test_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${directory.path}/inkash.db',
    );
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  Map<String, Object?> movimiento(int categoriaId) => {
    'id': 'movimiento-1',
    'titulo': 'Uber al trabajo',
    'monto_centavos': -3800,
    'fecha': DateTime.utc(2026, 9, 17, 14, 30, 15, 123).millisecondsSinceEpoch,
    'categoria_id': categoriaId,
  };

  test('persiste movimientos relacionados al cerrar y abrir la base', () async {
    final db = await database.database;
    final categoriaId = await db.insert('categorias', {
      'nombre': 'Transporte',
      'icono': 'directions_bus',
    });
    await db.insert('movimientos', movimiento(categoriaId));
    await database.close();

    final reopened = await database.database;
    final rows = await reopened.rawQuery('''
      SELECT m.monto_centavos, m.fecha, c.nombre
      FROM movimientos m JOIN categorias c ON c.id = m.categoria_id
    ''');
    expect(rows, [
      {
        'monto_centavos': -3800,
        'fecha': DateTime.utc(
          2026,
          9,
          17,
          14,
          30,
          15,
          123,
        ).millisecondsSinceEpoch,
        'nombre': 'Transporte',
      },
    ]);
    expect(await reopened.getVersion(), AppDatabase.versionActual);
  });

  test('rechaza categorías inexistentes y protege categorías en uso', () async {
    final db = await database.database;
    await expectLater(
      db.insert('movimientos', movimiento(999)),
      throwsA(isA<DatabaseException>()),
    );
    final categoriaId = await db.insert('categorias', {
      'nombre': 'Transporte',
      'icono': 'directions_bus',
    });
    await db.insert('movimientos', movimiento(categoriaId));
    await expectLater(
      db.delete('categorias', where: 'id = ?', whereArgs: [categoriaId]),
      throwsA(isA<DatabaseException>()),
    );
    await database.close();
    final reopened = await database.database;
    await expectLater(
      reopened.update('movimientos', {'categoria_id': 999}),
      throwsA(isA<DatabaseException>()),
    );
  });

  test(
    'el signo distingue ingresos de gastos y permite calcular el saldo',
    () async {
      final db = await database.database;
      final categoriaId = await db.insert('categorias', {
        'nombre': 'General',
        'icono': 'attach_money',
      });
      await db.insert('movimientos', movimiento(categoriaId));
      await db.insert('movimientos', {
        ...movimiento(categoriaId),
        'id': 'movimiento-2',
        'titulo': 'Ingreso',
        'monto_centavos': 10000,
      });
      final saldo = await db.rawQuery(
        'SELECT SUM(monto_centavos) AS saldo FROM movimientos',
      );
      expect(saldo.single['saldo'], 6200);
    },
  );

  // Crea una base EXACTAMENTE como la dejaba la app en la versión 1 (S11).
  Future<String> crearBaseV1() async {
    final path = '${directory.path}/v1.db';
    final v1 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => AppDatabase.migraciones[1]!(db),
      ),
    );
    final categoriaId = await v1.insert('categorias', {
      'nombre': 'Hogar',
      'icono': 'home',
    });
    await v1.insert('movimientos', movimiento(categoriaId));
    await v1.close();
    return path;
  }

  // La prueba más importante de una migración: el usuario que ya tenía la
  // app (versión 1) actualiza y NO pierde sus movimientos.
  test('migra de la versión 1 a la actual sin perder datos', () async {
    final actualizada = AppDatabase(
      factory: databaseFactoryFfi,
      path: await crearBaseV1(),
    );
    final db = await actualizada.database;

    expect(await db.getVersion(), AppDatabase.versionActual);
    expect(await db.query('categorias'), hasLength(1));
    expect(await db.query('cache_tipo_cambio'), isEmpty);
    // v3: el movimiento viejo quedó asignado a "Efectivo".
    final fila = (await db.rawQuery('''
      SELECT m.titulo, c.nombre AS cuenta
      FROM movimientos m JOIN cuentas c ON c.id = m.cuenta_id
    ''')).single;
    expect(fila, {'titulo': 'Uber al trabajo', 'cuenta': 'Efectivo'});
    await actualizada.close();
  });

  // Si onCreate y onUpgrade divergen, un usuario nuevo y uno actualizado
  // tendrían bases distintas. Esta prueba lo detecta comparando el esquema.
  test('instalación nueva y actualizada tienen el mismo esquema', () async {
    Future<List<Object?>> esquema(AppDatabase base) async {
      final db = await base.database;
      final filas = await db.rawQuery(
        "SELECT type, name FROM sqlite_master WHERE name NOT LIKE 'sqlite_%' "
        'ORDER BY type, name',
      );
      final columnas = [
        for (final t in filas.where((f) => f['type'] == 'table'))
          for (final c in await db.rawQuery('PRAGMA table_info(${t['name']})'))
            '${t['name']}.${c['name']} ${c['type']}',
      ];
      return [...filas, ...columnas];
    }

    final nueva = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${directory.path}/nueva.db',
    );
    final actualizada = AppDatabase(
      factory: databaseFactoryFfi,
      path: await crearBaseV1(),
    );
    expect(await esquema(actualizada), await esquema(nueva));
    await nueva.close();
    await actualizada.close();
  });
}
