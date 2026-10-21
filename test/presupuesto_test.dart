import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inkash/core/database/app_database.dart';
import 'package:inkash/features/home/data/datasources/movimientos_local_data_source.dart';
import 'package:inkash/features/home/domain/nuevo_movimiento.dart';
import 'package:inkash/features/presupuesto/data/presupuesto_local_data_source.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late AppDatabase database;
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('inkash_presupuesto_');
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
    'lista TODAS las categorías de gasto, aunque no tengan gastos',
    () async {
      final movimientos = MovimientosLocalDataSource(database: database);
      final presupuesto = PresupuestoLocalDataSource(database: database);
      Future<void> gasto(String categoria, int centavos, DateTime fecha) =>
          movimientos.insertar(
            NuevoMovimiento(
              titulo: 'x',
              montoCentavos: centavos,
              esIngreso: false,
              categoria: categoria,
              fecha: fecha,
            ),
          );
      await gasto('Transporte', 3800, DateTime(2026, 10, 3));
      await gasto('Transporte', 1200, DateTime(2026, 9, 30)); // otro mes
      await gasto('Hogar', 289500, DateTime(2026, 10, 5));

      final filas = await presupuesto.obtenerDelMes(DateTime(2026, 10, 15));
      final gastado = {for (final f in filas) f.nombre: f.gastadoCentavos};

      // 5 categorías de gasto (Ingreso no se presupuesta). Servicios no tiene
      // gastos y aun así aparece con 0: el filtro de mes está en el ON.
      expect(gastado, {
        'Entretenimiento': 0,
        'Hogar': 289500,
        'Servicios': 0,
        'Súper y comida': 0,
        'Transporte': 3800,
      });
    },
  );

  test('definir, exceder y quitar un límite', () async {
    final movimientos = MovimientosLocalDataSource(database: database);
    final presupuesto = PresupuestoLocalDataSource(database: database);
    await movimientos.insertar(
      NuevoMovimiento(
        titulo: 'Súper',
        montoCentavos: 60000,
        esIngreso: false,
        categoria: 'Súper y comida',
        fecha: DateTime(2026, 10, 10),
      ),
    );
    final mes = DateTime(2026, 10);
    final super_ = (await presupuesto.obtenerDelMes(
      mes,
    )).firstWhere((f) => f.nombre == 'Súper y comida');

    await presupuesto.definirLimite(super_.categoriaId, 50000);
    var fila = (await presupuesto.obtenerDelMes(mes)).first;
    // Las categorías con límite salen primero.
    expect(fila.nombre, 'Súper y comida');
    expect(fila.limiteCentavos, 50000);
    expect(fila.excedido, isTrue);
    expect(fila.progreso, 1.0); // la barra no se desborda

    await presupuesto.definirLimite(super_.categoriaId, 80000); // upsert
    fila = (await presupuesto.obtenerDelMes(mes)).first;
    expect(fila.limiteCentavos, 80000);
    expect(fila.excedido, isFalse);

    await presupuesto.definirLimite(super_.categoriaId, null);
    expect(
      (await presupuesto.obtenerDelMes(
        mes,
      )).every((f) => f.limiteCentavos == null),
      isTrue,
    );
  });
}
