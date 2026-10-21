import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/features/metas/data/metas_repository.dart';
import 'package:inkash/features/metas/domain/meta.dart';

final metasRepositoryProvider = Provider<MetasRepository>(
  (ref) => MetasRepository(),
);

final metasProvider = FutureProvider<List<Meta>>(
  (ref) => ref.watch(metasRepositoryProvider).obtenerTodas(),
  retry: (_, _) => null,
);
