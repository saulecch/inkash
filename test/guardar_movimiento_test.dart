import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkash/core/database/app_database.dart';
import 'package:inkash/features/categorias/domain/categoria.dart';
import 'package:inkash/core/format/parse_monto.dart';
import 'package:inkash/features/home/data/datasources/movimientos_local_data_source.dart';
import 'package:inkash/features/home/domain/movimiento.dart';
import 'package:inkash/features/home/domain/nuevo_movimiento.dart';
import 'package:inkash/features/home/presentation/widgets/movimiento_bottom_sheet.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// s16-02: el formulario recibe las categorías (antes estaban escritas en él).
const categoriasDePrueba = [
  Categoria(
    id: 1,
    nombre: 'Transporte',
    icono: 'directions_bus',
    tipo: TipoCategoria.gasto,
  ),
  Categoria(
    id: 2,
    nombre: 'Salario',
    icono: 'work',
    tipo: TipoCategoria.ingreso,
  ),
];

void main() {
  group('parseMontoCentavos (sin double)', () {
    test('convierte texto a centavos enteros', () {
      expect(parseMontoCentavos('12.5'), 1250);
      expect(parseMontoCentavos('12.50'), 1250);
      expect(parseMontoCentavos('0.05'), 5);
      expect(parseMontoCentavos('1,250'), 125000);
      expect(parseMontoCentavos(' 38 '), 3800);
    });

    test('rechaza cero, negativos, 3 decimales y basura', () {
      for (final invalido in [
        '',
        '0',
        '0.00',
        '-1',
        '12.345',
        'abc',
        '1.2.3',
      ]) {
        expect(parseMontoCentavos(invalido), isNull, reason: invalido);
      }
    });
  });

  group('MovimientosLocalDataSource.insertar', () {
    sqfliteFfiInit();
    late AppDatabase database;
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('inkash_guardar_');
      database = AppDatabase(
        factory: databaseFactoryFfi,
        path: '${directory.path}/inkash.db',
      );
    });

    tearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });

    NuevoMovimiento bus({bool esIngreso = false}) => NuevoMovimiento(
      titulo: 'Bus demo',
      montoCentavos: 1250,
      esIngreso: esIngreso,
      categoria: 'Transporte',
      fecha: DateTime(2026, 10, 15, 8, 15),
    );

    test('guarda el gasto negativo y sobrevive a cerrar la base', () async {
      final dataSource = MovimientosLocalDataSource(database: database);
      await dataSource.insertar(bus());
      await dataSource.insertar(bus());

      // "Cerrar la app": se cierra el archivo y se vuelve a abrir.
      await database.close();
      final db = await database.database;

      final movimientos = await db.query('movimientos');
      expect(movimientos, hasLength(2));
      expect(movimientos.first['monto_centavos'], -1250);

      // Dos movimientos de Transporte reutilizan UNA sola categoría
      // (desde v4 la categoría ya existe: la crea la migración).
      final transporte = await db.query(
        'categorias',
        where: 'nombre = ?',
        whereArgs: ['Transporte'],
      );
      expect(transporte, hasLength(1));
      expect(movimientos.map((m) => m['categoria_id']).toSet(), {
        transporte.single['id'],
      });
    });

    test('actualizar cambia los datos y conserva el id', () async {
      final dataSource = MovimientosLocalDataSource(database: database);
      await dataSource.insertar(bus());
      final antes = (await dataSource.obtenerMovimientos()).single;

      await dataSource.actualizar(
        antes.id,
        NuevoMovimiento(
          titulo: 'Taxi',
          montoCentavos: 4500,
          esIngreso: false,
          categoria: 'Hogar',
          fecha: antes.fechaHora,
        ),
      );

      final despues = (await dataSource.obtenerMovimientos()).single;
      expect(despues.id, antes.id);
      expect(despues.titulo, 'Taxi');
      expect(despues.montoCentavos, 4500);
      expect(despues.categoria, 'Hogar');
    });

    test('eliminar devuelve la fila y restaurar la deja idéntica', () async {
      final dataSource = MovimientosLocalDataSource(database: database);
      await dataSource.insertar(bus());
      final db = await database.database;
      final antes = (await db.query('movimientos')).single;

      final eliminado = await dataSource.eliminar(antes['id']! as String);
      expect(await db.query('movimientos'), isEmpty);
      expect(await dataSource.eliminar('no-existe'), isNull);

      await dataSource.restaurar(eliminado!);
      // Mismo id, categoría, fecha y monto: es EL mismo registro.
      expect((await db.query('movimientos')).single, antes);
    });

    test('obtenerMovimientos filtra por mes y categoría', () async {
      final dataSource = MovimientosLocalDataSource(database: database);
      Future<void> mov(String titulo, String categoria, DateTime fecha) =>
          dataSource.insertar(
            NuevoMovimiento(
              titulo: titulo,
              montoCentavos: 100,
              esIngreso: false,
              categoria: categoria,
              fecha: fecha,
            ),
          );
      await mov('Bus', 'Transporte', DateTime(2026, 10, 2));
      await mov('Súper', 'Súper y comida', DateTime(2026, 10, 3));
      await mov('Bus sept', 'Transporte', DateTime(2026, 9, 28));

      List<String> titulos(List<Movimiento> l) => [for (final m in l) m.titulo];
      expect(
        titulos(await dataSource.obtenerMovimientos(mes: DateTime(2026, 10))),
        ['Súper', 'Bus'],
      );
      expect(
        titulos(await dataSource.obtenerMovimientos(categoria: 'Transporte')),
        ['Bus', 'Bus sept'],
      );
      expect(
        titulos(
          await dataSource.obtenerMovimientos(
            mes: DateTime(2026, 9),
            categoria: 'Transporte',
          ),
        ),
        ['Bus sept'],
      );
      expect(await dataSource.obtenerCategoriasUsadas(), [
        'Súper y comida',
        'Transporte',
      ]);
    });

    test('totalesDelMes suma con SQL solo el mes pedido', () async {
      final dataSource = MovimientosLocalDataSource(database: database);
      NuevoMovimiento mov(int centavos, bool ingreso, DateTime fecha) =>
          NuevoMovimiento(
            titulo: 'x',
            montoCentavos: centavos,
            esIngreso: ingreso,
            categoria: 'Hogar',
            fecha: fecha,
          );
      await dataSource.insertar(mov(1000, false, DateTime(2026, 10, 1)));
      await dataSource.insertar(
        mov(2550, false, DateTime(2026, 10, 31, 23, 59)),
      );
      await dataSource.insertar(mov(50000, true, DateTime(2026, 10, 15)));
      // Bordes: el 30 de sept y el 1 de nov NO son de octubre.
      await dataSource.insertar(
        mov(9999, false, DateTime(2026, 9, 30, 23, 59)),
      );
      await dataSource.insertar(mov(9999, false, DateTime(2026, 11, 1)));

      final octubre = await dataSource.totalesDelMes(DateTime(2026, 10, 20));
      expect(octubre.gastosCentavos, 3550);
      expect(octubre.ingresosCentavos, 50000);

      final vacio = await dataSource.totalesDelMes(DateTime(2026, 1));
      expect(vacio.gastosCentavos, 0); // COALESCE: 0, no null
      expect(await dataSource.obtenerMovimientos(limite: 2), hasLength(2));
    });

    test(
      'obtenerMovimientos: más reciente primero y signo -> esIngreso',
      () async {
        final dataSource = MovimientosLocalDataSource(database: database);
        await dataSource.insertar(bus());
        await dataSource.insertar(
          NuevoMovimiento(
            titulo: 'Salario',
            montoCentavos: 420000,
            esIngreso: true,
            categoria: 'Ingreso',
            fecha: DateTime(2026, 10, 16, 9),
          ),
        );

        final movimientos = await dataSource.obtenerMovimientos(
          ahora: DateTime(2026, 10, 16, 12),
        );

        expect(movimientos.map((m) => m.titulo), ['Salario', 'Bus demo']);
        expect(movimientos.first.esIngreso, isTrue);
        expect(movimientos.last.montoCentavos, 1250); // positivo en el dominio
        expect(movimientos.last.esIngreso, isFalse);
        expect(movimientos.map((m) => m.fecha), ['Hoy', 'Ayer']);
      },
    );
  });

  group('MovimientoBottomSheet', () {
    Future<void> llenarFormulario(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField).at(0), '12.50');
      await tester.enterText(find.byType(TextField).at(1), 'Bus demo');
      await tester.tap(find.text('Transporte'));
      await tester.pump();
    }

    testWidgets(
      'el botón está deshabilitado hasta que el formulario es válido',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MovimientoBottomSheet(
                onGuardar: (_) async {},
                categorias: categoriasDePrueba,
              ),
            ),
          ),
        );
        FilledButton boton() => tester.widget(find.byType(FilledButton));

        expect(boton().onPressed, isNull);
        await llenarFormulario(tester);
        expect(boton().onPressed, isNotNull);
      },
    );

    testWidgets('doble toque guarda una sola vez', (tester) async {
      var llamadas = 0;
      // El Completer deja el guardado "colgado" para simular una base lenta.
      final pendiente = Completer<void>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovimientoBottomSheet(
              categorias: categoriasDePrueba,
              onGuardar: (nuevo) {
                llamadas++;
                expect(nuevo.montoCentavos, 1250);
                return pendiente.future;
              },
            ),
          ),
        ),
      );
      await llenarFormulario(tester);
      // El botón queda abajo del scroll: hay que traerlo a la vista.
      await tester.ensureVisible(find.byType(FilledButton));
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();

      expect(llamadas, 1);
      expect(find.text('Guardando…'), findsOneWidget);
      pendiente.complete();
    });
  });
}
