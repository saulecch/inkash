import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/features/categorias/data/categorias_repository.dart';
import 'package:inkash/features/categorias/domain/categoria.dart';

final categoriasRepositoryProvider = Provider<CategoriasRepository>(
  (ref) => CategoriasRepository(),
);

// Todas (incluidas archivadas): la pantalla de gestión las muestra todas;
// el formulario filtra las activas del tipo que corresponda.
final categoriasProvider = FutureProvider<List<Categoria>>(
  (ref) => ref.watch(categoriasRepositoryProvider).obtenerTodas(),
  retry: (_, _) => null,
);
