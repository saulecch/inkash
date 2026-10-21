import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkash/core/database/app_database.dart';
import 'package:inkash/features/categorias/data/categorias_local_data_source.dart';
import 'package:inkash/features/categorias/data/categorias_repository.dart';
import 'package:inkash/features/categorias/domain/categoria.dart';
import 'package:inkash/features/home/data/datasources/movimientos_local_data_source.dart';
import 'package:inkash/features/home/domain/nuevo_movimiento.dart';
import 'package:inkash/features/home/presentation/widgets/movimiento_bottom_sheet.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('CategoriasRepository', () {
    sqfliteFfiInit();
    late AppDatabase database;
    late Directory directory;
    late CategoriasRepository categorias;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('inkash_categorias_');
      database = AppDatabase(
        factory: databaseFactoryFfi,
        path: '${directory.path}/inkash.db',
      );
      categorias = CategoriasRepository(
        localDataSource: CategoriasLocalDataSource(database: database),
      );
    });

    tearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });

    test('la migración siembra categorías de gasto y de ingreso', () async {
      final todas = await categorias.obtenerTodas();
      expect(
        todas.where((c) => c.esIngreso).map((c) => c.nombre),
        containsAll(['Salario', 'Otros ingresos']),
      );
      expect(todas.where((c) => !c.esIngreso), hasLength(5));
    });

    test('crear, nombre único, archivar y borrar solo si no se usó', () async {
      await categorias.guardar(
        nombre: 'Mascotas',
        icono: 'pets',
        tipo: TipoCategoria.gasto,
      );
      await expectLater(
        categorias.guardar(
          nombre: 'Mascotas',
          icono: 'pets',
          tipo: TipoCategoria.gasto,
        ),
        throwsA(isA<CategoriaException>()),
      );

      Future<Categoria> buscar(String nombre) async =>
          (await categorias.obtenerTodas()).firstWhere(
            (c) => c.nombre == nombre,
          );

      // Usada: no se borra, se archiva (y va al final de la lista).
      await MovimientosLocalDataSource(database: database).insertar(
        NuevoMovimiento(
          titulo: 'Concentrado',
          montoCentavos: 18000,
          esIngreso: false,
          categoria: 'Mascotas',
          fecha: DateTime(2026, 10, 20),
        ),
      );
      final mascotas = await buscar('Mascotas');
      await expectLater(
        categorias.eliminar(mascotas.id),
        throwsA(isA<CategoriaException>()),
      );
      await categorias.archivar(mascotas.id, archivada: true);
      expect((await buscar('Mascotas')).archivada, isTrue);
      expect((await categorias.obtenerTodas()).last.nombre, 'Mascotas');

      // Sin uso: se borra.
      final otros = await buscar('Otros ingresos');
      await categorias.eliminar(otros.id);
      expect(
        (await categorias.obtenerTodas()).any(
          (c) => c.nombre == 'Otros ingresos',
        ),
        isFalse,
      );
    });
  });

  testWidgets(
    'formulario: solo categorías del tipo y "+ Nueva" la selecciona',
    (tester) async {
      const categorias = [
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
        Categoria(
          id: 3,
          nombre: 'Viejo',
          icono: 'home',
          tipo: TipoCategoria.gasto,
          archivada: true,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MovimientoBottomSheet(
              onGuardar: (_) async {},
              categorias: categorias,
              onNuevaCategoria: (tipo) async =>
                  Categoria(id: 9, nombre: 'Bono', icono: 'gift', tipo: tipo),
            ),
          ),
        ),
      );

      // Gasto: Transporte sí; Salario (ingreso) y Viejo (archivada) no.
      expect(find.text('Transporte'), findsOneWidget);
      expect(find.text('Salario'), findsNothing);
      expect(find.text('Viejo'), findsNothing);

      await tester.tap(find.text('Ingreso'));
      await tester.pumpAndSettle();
      expect(find.text('Salario'), findsOneWidget);
      expect(find.text('Transporte'), findsNothing);

      await tester.ensureVisible(find.text('Nueva'));
      await tester.tap(find.text('Nueva'));
      await tester.pumpAndSettle();
      final bono = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Bono'),
      );
      expect(bono.selected, isTrue);
    },
  );
}
