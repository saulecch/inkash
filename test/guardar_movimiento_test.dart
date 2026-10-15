import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkash/core/database/app_database.dart';
import 'package:inkash/core/format/parse_monto.dart';
import 'package:inkash/features/home/data/datasources/movimientos_local_data_source.dart';
import 'package:inkash/features/home/domain/nuevo_movimiento.dart';
import 'package:inkash/features/home/presentation/widgets/movimiento_bottom_sheet.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

      // Dos movimientos de Transporte reutilizan UNA sola categoría.
      final categorias = await db.query('categorias');
      expect(categorias, [
        {'id': 1, 'nombre': 'Transporte', 'icono': 'directions_bus'},
      ]);
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
              body: MovimientoBottomSheet(onGuardar: (_) async {}),
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
