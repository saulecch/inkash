import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkash/core/database/app_database.dart';
import 'package:inkash/features/metas/data/metas_local_data_source.dart';
import 'package:inkash/features/metas/data/metas_repository.dart';
import 'package:inkash/features/metas/domain/meta.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late Directory directory;
  late MetasRepository metas;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inkash_metas_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${directory.path}/inkash.db',
    );
    metas = MetasRepository(
      localDataSource: MetasLocalDataSource(database: database),
    );
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('aportes simultáneos no se pierden (UPDATE atómico)', () async {
    await metas.crear('Viaje a Tikal', 200000);
    final id = (await metas.obtenerTodas()).single.id;

    // 10 aportes "a la vez". Con leer-sumar-escribir en Dart se perderían.
    await Future.wait([for (var i = 0; i < 10; i++) metas.aportar(id, 1000)]);

    expect((await metas.obtenerTodas()).single.ahorradoCentavos, 10000);
  });

  test('no se puede retirar más de lo ahorrado', () async {
    await metas.crear('Laptop', 800000);
    final id = (await metas.obtenerTodas()).single.id;
    await metas.aportar(id, 5000);

    await expectLater(metas.retirar(id, 5001), throwsA(isA<MetaException>()));
    await metas.retirar(id, 5000);
    expect((await metas.obtenerTodas()).single.ahorradoCentavos, 0);

    // Última defensa: aunque alguien salte la app, el CHECK lo impide.
    final db = await database.database;
    await expectLater(
      db.update('metas', {'ahorrado_centavos': -1}),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('las completadas van al final', () async {
    await metas.crear('Celular', 1000);
    await metas.crear('Fondo de emergencia', 500000);
    final celular = (await metas.obtenerTodas()).first;
    await metas.aportar(celular.id, 1000);

    final lista = await metas.obtenerTodas();
    expect(lista.map((m) => m.nombre), ['Fondo de emergencia', 'Celular']);
    expect(lista.last.completada, isTrue);
  });

  test('editar nombre y objetivo conserva lo ahorrado; eliminar', () async {
    await metas.crear('Laptp', 800000);
    final id = (await metas.obtenerTodas()).single.id;
    await metas.aportar(id, 20000);

    await metas.editar(id, '  Laptop ', 900000);
    final meta = (await metas.obtenerTodas()).single;
    expect(meta.nombre, 'Laptop');
    expect(meta.objetivoCentavos, 900000);
    expect(meta.ahorradoCentavos, 20000);

    await metas.eliminar(id);
    expect(await metas.obtenerTodas(), isEmpty);
  });
}
