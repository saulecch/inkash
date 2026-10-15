import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:inkash/core/database/app_database.dart';
import 'package:inkash/features/tipo_cambio/data/tipo_cambio_api.dart';
import 'package:inkash/features/tipo_cambio/data/tipo_cambio_cache.dart';
import 'package:inkash/features/tipo_cambio/data/tipo_cambio_repository.dart';
import 'package:inkash/features/tipo_cambio/domain/tipo_cambio.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// MockClient = un "servidor" falso. Las pruebas no dependen de internet.
TipoCambioApi apiQueResponde(int status, String body) =>
    TipoCambioApi(client: MockClient((_) async => http.Response(body, status)));

const jsonOk = '{"result":"success","rates":{"USD":1,"GTQ":7.6543}}';

void main() {
  group('TipoCambioApi: las 4 formas de fallar', () {
    test('200 con JSON válido -> entero en diezmilésimas', () async {
      expect(
        await apiQueResponde(200, jsonOk).obtenerQuetzalesPorDolar(),
        76543,
      );
    });

    test('500 -> TipoCambioException con el código', () async {
      await expectLater(
        apiQueResponde(500, 'error').obtenerQuetzalesPorDolar(),
        throwsA(
          isA<TipoCambioException>().having(
            (e) => e.mensaje,
            'mensaje',
            contains('500'),
          ),
        ),
      );
    });

    test('200 pero JSON inesperado -> TipoCambioException', () async {
      await expectLater(
        apiQueResponde(200, '{"rates":{}}').obtenerQuetzalesPorDolar(),
        throwsA(isA<TipoCambioException>()),
      );
    });

    test('sin internet -> "Sin conexión"', () async {
      final api = TipoCambioApi(
        client: MockClient((_) => throw http.ClientException('offline')),
      );
      await expectLater(
        api.obtenerQuetzalesPorDolar(),
        throwsA(
          isA<TipoCambioException>().having(
            (e) => e.mensaje,
            'mensaje',
            'Sin conexión a internet.',
          ),
        ),
      );
    });

    test('servidor lento -> timeout', () async {
      final api = TipoCambioApi(
        timeout: const Duration(milliseconds: 50),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(seconds: 1));
          return http.Response(jsonOk, 200);
        }),
      );
      await expectLater(
        api.obtenerQuetzalesPorDolar(),
        throwsA(isA<TipoCambioException>()),
      );
    });
  });

  group('TipoCambioRepository: red primero, caché si falla', () {
    sqfliteFfiInit();
    late AppDatabase database;
    late Directory directory;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('inkash_tc_');
      database = AppDatabase(
        factory: databaseFactoryFfi,
        path: '${directory.path}/inkash.db',
      );
    });

    tearDown(() async {
      await database.close();
      await directory.delete(recursive: true);
    });

    test('con red guarda en caché; sin red devuelve el último dato', () async {
      final cache = TipoCambioCache(database: database);

      final enLinea = await TipoCambioRepository(
        api: apiQueResponde(200, jsonOk),
        cache: cache,
      ).obtener();
      expect(enLinea.desdeCache, isFalse);

      final sinRed = await TipoCambioRepository(
        api: apiQueResponde(503, 'caído'),
        cache: cache,
      ).obtener();
      expect(sinRed.desdeCache, isTrue);
      expect(sinRed.quetzalesPorDolarDiezmilesimas, 76543);
      expect(sinRed.centavosPorDolar, 765);
    });

    test('sin red y sin caché -> el error llega a la UI', () async {
      await expectLater(
        TipoCambioRepository(
          api: apiQueResponde(503, 'caído'),
          cache: TipoCambioCache(database: database),
        ).obtener(),
        throwsA(isA<TipoCambioException>()),
      );
    });
  });
}
