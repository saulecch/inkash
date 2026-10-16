import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkash/app.dart';
import 'package:inkash/features/home/data/repositories/movimientos_repository.dart';
import 'package:inkash/features/home/domain/movimiento.dart';
import 'package:inkash/features/home/presentation/controllers/home_controller.dart';
import 'package:inkash/features/tipo_cambio/domain/tipo_cambio.dart';
import 'package:inkash/features/tipo_cambio/presentation/tipo_cambio_provider.dart';

// Los datos de ejemplo de S09 ahora viven aquí: son datos de PRUEBA.
const movimientosDeEjemplo = [
  Movimiento(
    id: '1',
    titulo: 'Uber al trabajo',
    subtitulo: 'Transporte',
    icono: 'directions_bus',
    montoCentavos: 3800,
    fecha: 'Hoy',
  ),
  Movimiento(
    id: '2',
    titulo: 'Súper La Torre',
    subtitulo: 'Súper y comida',
    icono: 'shopping_cart',
    montoCentavos: 28550,
    fecha: 'Ayer',
  ),
  Movimiento(
    id: '3',
    titulo: 'Salario quincena',
    subtitulo: 'Ingreso',
    icono: 'arrow_upward',
    montoCentavos: 420000,
    fecha: 'Ayer',
    esIngreso: true,
  ),
  Movimiento(
    id: '4',
    titulo: 'Café con Ana',
    subtitulo: 'Entretenimiento',
    icono: 'local_cafe',
    montoCentavos: 6500,
    fecha: 'Ayer',
  ),
  Movimiento(
    id: '5',
    titulo: 'Recibo de luz (EEGSA)',
    subtitulo: 'Servicios',
    icono: 'bolt',
    montoCentavos: 42000,
    fecha: 'Lun 20',
  ),
  Movimiento(
    id: '6',
    titulo: 'Vivienda',
    subtitulo: 'Hogar',
    icono: 'home',
    montoCentavos: 289500,
    fecha: 'Jul 15',
  ),
];

// Repositorio falso: responde lo que la prueba quiera, sin SQLite.
class RepositorioFalso extends MovimientosRepository {
  RepositorioFalso(this.respuesta);

  Future<List<Movimiento>> Function() respuesta;

  @override
  Future<List<Movimiento>> obtenerMovimientos() => respuesta();
}

Widget appCon(RepositorioFalso repositorio) {
  return ProviderScope(
    // Override: en esta prueba, el provider entrega el repositorio falso.
    overrides: [
      movimientosRepositoryProvider.overrideWithValue(repositorio),
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
  test('ResumenHome suma los gastos y calcula el saldo disponible', () {
    const resumen = ResumenHome(
      movimientos: movimientosDeEjemplo,
      limiteMensualCentavos: 650000,
    );
    expect(resumen.totalGastadoCentavos, 370350);
    expect(resumen.saldoDisponibleCentavos, 279650);
  });

  testWidgets('cargando -> datos: muestra el saldo calculado', (tester) async {
    final lectura = Completer<List<Movimiento>>();
    await tester.pumpWidget(appCon(RepositorioFalso(() => lectura.future)));

    // Mientras el Future no termina: estado de carga.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    lectura.complete(movimientosDeEjemplo);
    await tester.pumpAndSettle();

    expect(find.text('Q2,796.50'), findsOneWidget);
    expect(find.text('Has usado Q3,703.50 de Q6,500.00'), findsOneWidget);
    expect(find.text('Dólar hoy · Q7.65'), findsOneWidget);
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

    expect(find.text('Q2,796.50'), findsOneWidget);
  });

  testWidgets(
    'la barra inferior cambia de pestaña y "Ver todo" abre Historial',
    (tester) async {
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
      expect(find.widgetWithText(Column, 'Historial'), findsWidgets);
      expect(find.text('Próximamente'), findsOneWidget);
    },
  );
}
