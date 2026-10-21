import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkash/app.dart';
import 'package:inkash/core/reloj.dart';
import 'package:inkash/features/categorias/domain/categoria.dart';
import 'package:inkash/features/categorias/presentation/categorias_provider.dart';
import 'package:inkash/features/cuentas/domain/cuenta.dart';
import 'package:inkash/features/cuentas/presentation/cuentas_provider.dart';
import 'package:inkash/features/home/data/repositories/movimientos_repository.dart';
import 'package:inkash/features/home/domain/movimiento.dart';
import 'package:inkash/features/home/domain/movimiento_eliminado.dart';
import 'package:inkash/features/home/domain/nuevo_movimiento.dart';
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
  categoria: categoria,
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

  // Borrar/restaurar sobre la lista en memoria (solo si la prueba la usa).
  List<Movimiento>? datos;
  final _borrados = <String, Movimiento>{};

  @override
  Future<MovimientoEliminado?> eliminar(String id) async {
    final m = datos!.firstWhere((m) => m.id == id);
    datos!.remove(m);
    _borrados[id] = m;
    return MovimientoEliminado({'id': id});
  }

  @override
  Future<void> actualizar(String id, NuevoMovimiento nuevo) async {
    final i = datos!.indexWhere((m) => m.id == id);
    final viejo = datos![i];
    datos![i] = Movimiento(
      id: id,
      titulo: nuevo.titulo,
      subtitulo: nuevo.categoria,
      icono: viejo.icono,
      montoCentavos: nuevo.montoCentavos,
      fecha: viejo.fecha,
      fechaHora: nuevo.fecha,
      esIngreso: nuevo.esIngreso,
      categoria: nuevo.categoria,
    );
  }

  @override
  Future<void> restaurar(MovimientoEliminado eliminado) async {
    datos!.add(_borrados.remove(eliminado.fila['id'])!);
    datos!.sort((a, b) => b.fechaHora.compareTo(a.fechaHora));
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
      // s16-01: cuentas fijas (la tarjeta del Inicio y el formulario).
      cuentasProvider.overrideWith(
        (ref) async => const [
          Cuenta(
            id: 1,
            nombre: 'Efectivo',
            icono: 'payments',
            saldoCentavos: 25000,
          ),
          Cuenta(
            id: 2,
            nombre: 'Banco',
            icono: 'account_balance',
            saldoCentavos: 756000,
          ),
        ],
      ),
      // s16-02: categorías fijas.
      categoriasProvider.overrideWith(
        (ref) async => const [
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
        ],
      ),
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
    expect(find.text('Q7,810.00'), findsOneWidget); // suma de las cuentas
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

    await tester.tap(find.text('Presupuesto'));
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

  testWidgets('Historial: deslizar elimina y "Deshacer" lo regresa', (
    tester,
  ) async {
    final datos = [...movimientosDeEjemplo];
    final repositorio = RepositorioFalso(() async => datos)..datos = datos;
    await tester.pumpWidget(appCon(repositorio));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Historial'));
    await tester.pumpAndSettle();

    await tester.drag(find.text('Café con Ana'), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.text('Café con Ana'), findsNothing);
    expect(find.text('"Café con Ana" eliminado'), findsOneWidget);
    // La fila salió de la "base" (falsa), no solo de la pantalla.
    expect(datos, hasLength(5));

    await tester.tap(find.text('Deshacer'));
    await tester.pumpAndSettle();
    expect(find.text('Café con Ana'), findsOneWidget);
    expect(datos, hasLength(6));
  });

  testWidgets('la tarjeta Cuentas abre la gestión de cuentas', (tester) async {
    await tester.pumpWidget(
      appCon(RepositorioFalso(() async => movimientosDeEjemplo)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Q7,810.00'));
    await tester.pumpAndSettle();

    expect(find.text('Nueva cuenta'), findsOneWidget);
    expect(find.text('Banco'), findsOneWidget);
    expect(find.text('Q7,560.00'), findsOneWidget);
  });

  testWidgets('Ajustes -> Categorías muestra gastos, ingresos y archivadas', (
    tester,
  ) async {
    await tester.pumpWidget(
      appCon(RepositorioFalso(() async => movimientosDeEjemplo)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Categorías'));
    await tester.pumpAndSettle();

    expect(find.text('Gastos'), findsOneWidget);
    expect(find.text('Ingresos'), findsOneWidget);
    expect(find.text('Archivadas'), findsOneWidget);
    expect(find.text('Salario'), findsOneWidget);
  });

  testWidgets('tocar un movimiento abre el formulario lleno y guarda cambios', (
    tester,
  ) async {
    final datos = [...movimientosDeEjemplo];
    final repositorio = RepositorioFalso(() async => datos)..datos = datos;
    await tester.pumpWidget(appCon(repositorio));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Uber al trabajo'));
    await tester.pumpAndSettle();

    expect(find.text('Editar movimiento'), findsOneWidget);
    expect(find.widgetWithText(TextField, '38.00'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, '38.00'), '40');
    await tester.ensureVisible(find.text('Guardar cambios'));
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(find.text('Cambios guardados'), findsOneWidget);
    expect(datos.first.montoCentavos, 4000);
    expect(datos.first.id, '1'); // mismo registro, no uno nuevo
  });
}
