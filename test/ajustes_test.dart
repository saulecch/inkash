import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkash/core/database/app_database.dart';
import 'package:inkash/features/ajustes/data/ajustes_local_data_source.dart';
import 'package:inkash/features/ajustes/domain/ajustes.dart';
import 'package:inkash/features/home/data/datasources/movimientos_local_data_source.dart';
import 'package:inkash/features/home/domain/nuevo_movimiento.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inkash_ajustes_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${directory.path}/inkash.db',
    );
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test('valores por defecto, guardar y sobrevivir al cierre', () async {
    final ajustes = AjustesLocalDataSource(database: database);
    final inicial = await ajustes.leer();
    expect(inicial.nombre, '');
    expect(inicial.saludo, 'Hola');
    expect(
      inicial.limiteMensualCentavos,
      Ajustes.porDefecto.limiteMensualCentavos,
    );

    await ajustes.guardarNombre('Kevin');
    await ajustes.guardarLimite(500000);
    await ajustes.guardarLimite(450000); // REPLACE: sigue siendo una fila
    await database.close();

    final leido = await ajustes.leer();
    expect(leido.saludo, 'Hola, Kevin');
    expect(leido.limiteMensualCentavos, 450000);
  });

  test('borrar datos del usuario conserva categorías y cuentas', () async {
    final ajustes = AjustesLocalDataSource(database: database);
    await ajustes.guardarNombre('Kevin');
    await MovimientosLocalDataSource(database: database).insertar(
      NuevoMovimiento(
        titulo: 'Bus',
        montoCentavos: 500,
        esIngreso: false,
        categoria: 'Transporte',
        fecha: DateTime(2026, 11, 3),
      ),
    );

    await ajustes.marcarBienvenidaCompleta();
    expect((await ajustes.leer()).bienvenidaCompleta, isTrue);

    await ajustes.borrarDatosDelUsuario();
    // Empezar de cero = volver a ver la bienvenida.
    expect((await ajustes.leer()).bienvenidaCompleta, isFalse);

    final db = await database.database;
    expect(await db.query('movimientos'), isEmpty);
    expect(await db.query('ajustes'), isEmpty);
    expect(await db.query('categorias'), hasLength(7));
    expect(await db.query('cuentas'), hasLength(3));
  });
}
