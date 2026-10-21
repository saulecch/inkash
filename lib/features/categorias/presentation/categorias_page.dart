import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/core/widgets/iconos.dart';
import 'package:inkash/features/categorias/domain/categoria.dart';
import 'package:inkash/features/categorias/presentation/categoria_sheet.dart';
import 'package:inkash/features/categorias/presentation/categorias_provider.dart';
import 'package:inkash/features/historial/historial_controller.dart';
import 'package:inkash/features/home/presentation/controllers/home_controller.dart';
import 'package:inkash/theme.dart';

class CategoriasPage extends ConsumerWidget {
  const CategoriasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categorias = ref.watch(categoriasProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => abrirFormularioCategoria(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva categoría'),
      ),
      body: categorias.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(categoriasProvider),
            child: const Text('No pudimos leer las categorías. Reintentar'),
          ),
        ),
        data: (lista) {
          Iterable<Categoria> de(TipoCategoria t) =>
              lista.where((c) => c.tipo == t && !c.archivada);
          final archivadas = lista.where((c) => c.archivada);
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              _Seccion('Gastos', de(TipoCategoria.gasto), ref),
              _Seccion('Ingresos', de(TipoCategoria.ingreso), ref),
              if (archivadas.isNotEmpty)
                _Seccion('Archivadas', archivadas, ref),
            ],
          );
        },
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion(this.titulo, this.categorias, this.ref);

  final String titulo;
  final Iterable<Categoria> categorias;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            titulo,
            style: const TextStyle(color: kLima, fontSize: 12),
          ),
        ),
        for (final c in categorias)
          ListTile(
            leading: Icon(
              iconoDe(c.icono),
              color: c.archivada ? kMuted : kLima,
            ),
            title: Text(
              c.nombre,
              style: TextStyle(color: c.archivada ? kMuted : kTexto),
            ),
            trailing: const Icon(Icons.chevron_right, color: kMuted),
            onTap: () => abrirFormularioCategoria(context, ref, categoria: c),
          ),
      ],
    );
  }
}

// Abre el formulario de categoría. Devuelve el nombre guardado (o null).
// Lo usan esta pantalla y el formulario de movimientos ("+ Nueva").
Future<String?> abrirFormularioCategoria(
  BuildContext context,
  WidgetRef ref, {
  Categoria? categoria,
  TipoCategoria tipoInicial = TipoCategoria.gasto,
}) {
  final repo = ref.read(categoriasRepositoryProvider);
  // El nombre de la categoría aparece en movimientos, chips y presupuesto.
  void refrescar() {
    ref.invalidate(categoriasProvider);
    ref.invalidate(homeControllerProvider);
    ref.invalidate(historialProvider);
    ref.invalidate(categoriasUsadasProvider);
  }

  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: kSuperficie,
    builder: (_) => CategoriaSheet(
      categoria: categoria,
      tipoInicial: tipoInicial,
      onGuardar: (d) async {
        await repo.guardar(
          id: categoria?.id,
          nombre: d.nombre,
          icono: d.icono,
          tipo: d.tipo,
        );
        refrescar();
      },
      onArchivar: categoria == null
          ? null
          : () async {
              await repo.archivar(
                categoria.id,
                archivada: !categoria.archivada,
              );
              refrescar();
            },
      onEliminar: categoria == null
          ? null
          : () async {
              await repo.eliminar(categoria.id);
              refrescar();
            },
    ),
  );
}
