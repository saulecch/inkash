import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkash/app.dart';
import 'package:inkash/core/reloj.dart';
import 'package:inkash/features/home/data/repositories/movimientos_repository.dart';
import 'package:inkash/features/home/domain/movimiento.dart';
import 'package:inkash/features/home/domain/totales_mes.dart';
import 'package:inkash/features/home/presentation/controllers/home_controller.dart';
import 'package:inkash/features/tipo_cambio/domain/tipo_cambio.dart';
import 'package:inkash/features/tipo_cambio/presentation/tipo_cambio_provider.dart';

// Los datos de ejemplo de S09 ahora viven aquí: son datos de PRUEBA.
// "Hoy" en estas pruebas es el 15 de octubre de 2026 (ver relojProvider).
Movimiento _mov(
  String id,
  String titulo,
  String categoria,
  String icono,
  int centavos,
  String etiqueta,
  DateTime fechaHora, {
  bool esIngreso = false,
}) => Movimiento(
  id: id,
  titulo: titulo,
  subtitulo: categoria,
  icono: icono,
  montoCentavos: centavos,
  fecha: etiqueta,
  fechaHora: fechaHora,
  esIngreso: esIngreso,
);

final movimientosDeEjemplo = [
  _mov(
    '1',
    'Uber al trabajo',
    'Transporte',
    'directions_bus',
    3800,
    'Hoy',
    DateTime(2026, 10, 15, 8),
  ),
  _mov(
    '2',
    'Súper La Torre',
    'Súper y comida',
    'shopping_cart',
    28550,
    'Ayer',
    DateTime(2026, 10, 14, 12),
  ),
  _mov(
    '3',
    'Salario quincena',
    'Ingreso',
    'arrow_upward',
    420000,
    'Ayer',
    DateTime(2026, 10, 14, 9),
    esIngreso: true,
  ),
  _mov(
    '4',
    'Café con Ana',
    'Entretenimiento',
    'local_cafe',
    6500,
    'Ayer',
    DateTime(2026, 10, 14, 8),
  ),
  _mov(
    '5',
    'Recibo de luz (EEGSA)',
    'Servicios',
    'bolt',
    42000,
    'Lun 12',
    DateTime(2026, 10, 12, 9),
  ),
  // Septiembre: NO cuenta para los totales de octubre.
  _mov(
    '6',
    'Vivienda',
    'Hogar',
    'home',
    289500,
    'Sep 15',
    DateTime(2026, 9, 15, 9),
  ),
];

// Repositorio falso: responde lo que la prueba quiera, sin SQLite.
// Imita los filtros del real sobre una lista en memoria.
class RepositorioFalso extends MovimientosRepository {
  RepositorioFalso(this.respuesta);

  Future<List<Movimiento>> Function() respuesta;

  static bool _delMes(Movimiento m, DateTime mes) =>
      m.fechaHora.year == mes.year && m.fechaHora.month == mes.month;

  @override
  Future<List<Movimiento>> obtenerMovimientos({
    int? limite,
    DateTime? mes,
    String? categoria,
  }) async {
    var lista = await respuesta();
    if (mes != null) lista = lista.where((m) => _delMes(m, mes)).toList();
    if (categoria != null) {
      lista = lista.where((m) => m.subtitulo == categoria).toList();
    }
    return limite == null ? lista : lista.take(limite).toList();
  }

  @override
  Future<List<String>> obtenerCategoriasUsadas() async =>
      {for (final m in await respuesta()) m.subtitulo}.toList()..sort();

  // En el falso sumamos en Dart; en el real lo hace SQLite (ver test de SQL).
  @override
  Future<TotalesMes> totalesDelMes(DateTime mes) async {
    final delMes = (await respuesta()).where((m) => _delMes(m, mes));
    int suma(bool ingreso) => delMes
        .where((m) => m.esIngreso == ingreso)
        .fold(0, (t, m) => t + m.montoCentavos);
    return TotalesMes(
      gastosCentavos: suma(false),
      ingresosCentavos: suma(true),
    );
  }
}

Widget appCon(RepositorioFalso repositorio) {
  return ProviderScope(
    // Override: en esta prueba, el provider entrega el repositorio falso.
    overrides: [
      movimientosRepositoryProvider.overrideWithValue(repositorio),
      // Reloj fijo: la prueba dice "Octubre 2026" hoy y dentro de un año.
      relojProvider.overrideWithValue(() => DateTime(2026, 10, 15, 9)),
      // La tarjeta del dólar no debe salir a internet en una prueba.
      tipoCambioProvider.overrideWith(
        (ref) async => TipoCambio(
          quetzalesPorDolarDiezmilesimas: 76543,
          actualizado: DateTime(2026, 10, 15, 8),
        ),
      ),
    ],
    child: const InkashApp(),
  );
}

void main() {
  test('ResumenHome calcula el saldo con el total del mes', () {
    final resumen = ResumenHome(
      mes: DateTime(2026, 10),
      ultimosMovimientos: const [],
      totalesMes: const TotalesMes(
        gastosCentavos: 80850,
        ingresosCentavos: 420000,
      ),
      limiteMensualCentavos: 650000,
    );
    expect(resumen.saldoDisponibleCentavos, 569150);
  });

  testWidgets('cargando -> datos: totales SOLO del mes actual', (tester) async {
    final lectura = Completer<List<Movimiento>>();
    await tester.pumpWidget(appCon(RepositorioFalso(() => lectura.future)));

    // Mientras el Future no termina: estado de carga.
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    lectura.complete(movimientosDeEjemplo);
    await tester.pumpAndSettle();

    // Q6,500 - Q808.50 de octubre. La vivienda de septiembre no cuenta.
    expect(find.text('Q5,691.50'), findsOneWidget);
    expect(find.text('Has usado Q808.50 de Q6,500.00'), findsOneWidget);
    expect(find.text('Dólar hoy · Q7.65'), findsOneWidget);
    expect(find.text('Octubre 2026'), findsOneWidget);
    // Solo los últimos 5 de 6 en el Inicio.
    expect(find.text('Vivienda'), findsNothing);
  });

  testWidgets('vacío: invita a registrar el primer movimiento', (tester) async {
    await tester.pumpWidget(appCon(RepositorioFalso(() async => [])));
    await tester.pumpAndSettle();

    expect(find.textContaining('Aún no hay movimientos'), findsOneWidget);
  });

  testWidgets('error -> Reintentar -> datos', (tester) async {
    final repositorio = RepositorioFalso(
      () async => throw Exception('disco lleno'),
    );
    await tester.pumpWidget(appCon(repositorio));
    await tester.pumpAndSettle();

    expect(find.text('No pudimos leer tus movimientos.'), findsOneWidget);

    // El usuario reintenta y esta vez la base responde.
    repositorio.respuesta = () async => movimientosDeEjemplo;
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Q5,691.50'), findsOneWidget);
  });

  testWidgets('la barra cambia de pestaña y "Ver todo" abre Historial', (
    tester,
  ) async {
    await tester.pumpWidget(
      appCon(RepositorioFalso(() async => movimientosDeEjemplo)),
    );
    await tester.pumpAndSettle();

    // IndexedStack: las pestañas ocultas existen pero están "offstage",
    // y find las ignora por defecto.
    expect(find.text('Próximamente'), findsNothing);

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Próximamente'), findsOneWidget);

    await tester.tap(find.text('Inicio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver todo'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Mes anterior'), findsOneWidget);
  });

  testWidgets('Historial: filtra por categoría y cambia de mes', (
    tester,
  ) async {
    await tester.pumpWidget(
      appCon(RepositorioFalso(() async => movimientosDeEjemplo)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();

    // Octubre: la vivienda de septiembre no aparece.
    expect(find.text('Octubre 2026'), findsOneWidget);
    expect(find.text('Café con Ana'), findsOneWidget);
    expect(find.text('Vivienda'), findsNothing);

    // Filtro por categoría: el provider se vuelve a ejecutar solo.
    // (Los chips están en una lista horizontal: usamos el primero, que
    // seguro está en pantalla.)
    await tester.tap(find.widgetWithText(ChoiceChip, 'Entretenimiento'));
    await tester.pumpAndSettle();
    expect(find.text('Café con Ana'), findsOneWidget);
    expect(find.text('Uber al trabajo'), findsNothing);

    // Volver a "Todas" y pasar a septiembre.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Todas'));
    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Septiembre 2026'), findsOneWidget);
    expect(find.text('Vivienda'), findsOneWidget);

    await tester.tap(find.byTooltip('Mes anterior'));
    await tester.pumpAndSettle();
    expect(find.text('Sin movimientos en este mes.'), findsOneWidget);
  });
}
