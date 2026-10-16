import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkash/core/database/app_database.dart';
import 'package:inkash/features/cuentas/data/cuentas_local_data_source.dart';
import 'package:inkash/features/cuentas/data/cuentas_repository.dart';
import 'package:inkash/features/cuentas/domain/cuenta.dart';
import 'package:inkash/features/home/data/datasources/movimientos_local_data_source.dart';
import 'package:inkash/features/home/domain/nuevo_movimiento.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inkash_cuentas_');
    database = AppDatabase(
      factory: databaseFactoryFfi,
      path: '${directory.path}/inkash.db',
    );
  });

  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test(
    'saldo por cuenta con LEFT JOIN: también las cuentas sin movimientos',
    () async {
      final movimientos = MovimientosLocalDataSource(database: database);
      final cuentas = CuentasLocalDataSource(database: database);
      final inicial = await cuentas.obtenerConSaldo();
      expect(inicial.map((c) => c.nombre), ['Efectivo', 'Banco', 'Tarjeta']);
      final efectivo = inicial.first.id;
      final banco = inicial[1].id;

      Future<void> mov(int centavos, bool ingreso, int cuentaId) =>
          movimientos.insertar(
            NuevoMovimiento(
              titulo: 'x',
              montoCentavos: centavos,
              esIngreso: ingreso,
              categoria: 'Hogar',
              fecha: DateTime(2026, 10, 20),
              cuentaId: cuentaId,
            ),
          );
      await mov(420000, true, banco);
      await mov(28550, false, banco);
      await mov(1250, false, efectivo);

      final saldos = {
        for (final c in await cuentas.obtenerConSaldo())
          c.nombre: c.saldoCentavos,
      };
      // Tarjeta no tiene movimientos y aun así aparece, con 0.
      expect(saldos, {'Efectivo': -1250, 'Banco': 391450, 'Tarjeta': 0});

      final lista = await movimientos.obtenerMovimientos();
      // El último insertado sale primero: categoría · cuenta.
      expect(lista.first.subtitulo, 'Hogar · Efectivo');
    },
  );

  test(
    'crear, editar saldo inicial, nombre único y borrar con reglas',
    () async {
      final cuentas = CuentasRepository(
        localDataSource: CuentasLocalDataSource(database: database),
      );
      await cuentas.guardar(
        nombre: 'Tarjeta BI',
        icono: 'credit_card',
        saldoInicialCentavos: -150000, // deuda
      );
      var bi = (await cuentas.obtenerConSaldo()).last;
      expect(bi.saldoCentavos, -150000);

      // Editar: el saldo inicial cambia el saldo (sin tocar movimientos).
      await cuentas.guardar(
        id: bi.id,
        nombre: 'Tarjeta BI',
        icono: 'credit_card',
        saldoInicialCentavos: -100000,
      );
      bi = (await cuentas.obtenerConSaldo()).last;
      expect(bi.saldoCentavos, -100000);

      // Nombre repetido: mensaje claro, no un error de SQL.
      await expectLater(
        cuentas.guardar(
          nombre: 'Efectivo',
          icono: 'payments',
          saldoInicialCentavos: 0,
        ),
        throwsA(isA<CuentaException>()),
      );

      // Con movimientos no se borra; sin movimientos sí.
      final efectivo = (await cuentas.obtenerConSaldo()).first;
      await MovimientosLocalDataSource(database: database).insertar(
        NuevoMovimiento(
          titulo: 'Bus',
          montoCentavos: 500,
          esIngreso: false,
          categoria: 'Transporte',
          fecha: DateTime(2026, 10, 20),
          cuentaId: efectivo.id,
        ),
      );
      await expectLater(
        cuentas.eliminar(efectivo.id),
        throwsA(isA<CuentaException>()),
      );
      await cuentas.eliminar(bi.id);
      expect((await cuentas.obtenerConSaldo()).map((c) => c.nombre), [
        'Efectivo',
        'Banco',
        'Tarjeta',
      ]);
    },
  );
}
