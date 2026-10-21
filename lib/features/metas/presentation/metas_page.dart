import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/core/format/formato_moneda.dart';
import 'package:inkash/core/widgets/hoja_monto.dart';
import 'package:inkash/features/metas/domain/meta.dart';
import 'package:inkash/features/metas/presentation/meta_sheet.dart';
import 'package:inkash/features/metas/presentation/metas_provider.dart';
import 'package:inkash/theme.dart';

// Pantalla que se ABRE ENCIMA (Navigator.push) desde la tarjeta del Inicio.
// No es una pestaña: tiene AppBar con flecha para volver.
class MetasPage extends ConsumerWidget {
  const MetasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metas = ref.watch(metasProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Metas de ahorro')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva meta'),
      ),
      body: metas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(metasProvider),
            child: const Text('No pudimos leer tus metas. Reintentar'),
          ),
        ),
        data: (lista) => lista.isEmpty
            ? const Center(
                child: Text(
                  'Aún no tienes metas.\nCrea la primera con "Nueva meta".',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kMuted),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                children: [
                  for (final meta in lista)
                    _FilaMeta(
                      meta: meta,
                      onMover: () => _moverDinero(context, ref, meta),
                      onEditar: () =>
                          _abrirFormulario(context, ref, meta: meta),
                    ),
                ],
              ),
      ),
    );
  }

  Future<void> _abrirFormulario(
    BuildContext context,
    WidgetRef ref, {
    Meta? meta,
  }) {
    final repo = ref.read(metasRepositoryProvider);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: kSuperficie,
      builder: (_) => MetaSheet(
        meta: meta,
        onGuardar: (d) async {
          meta == null
              ? await repo.crear(d.nombre, d.objetivoCentavos)
              : await repo.editar(meta.id, d.nombre, d.objetivoCentavos);
          ref.invalidate(metasProvider);
        },
        onEliminar: meta == null
            ? null
            : () async {
                await repo.eliminar(meta.id);
                ref.invalidate(metasProvider);
              },
      ),
    );
  }

  Future<void> _moverDinero(
    BuildContext context,
    WidgetRef ref,
    Meta meta,
  ) async {
    final respuesta = await pedirMonto(
      context,
      titulo: meta.nombre,
      ayuda:
          'Llevas ${formatQuetzales(meta.ahorradoCentavos)} de '
          '${formatQuetzales(meta.objetivoCentavos)}.',
      acciones: const ['Retirar', 'Aportar'],
    );
    final centavos = respuesta?.centavos;
    if (respuesta == null || centavos == null) return;

    final repo = ref.read(metasRepositoryProvider);
    try {
      respuesta.accion == 'Aportar'
          ? await repo.aportar(meta.id, centavos)
          : await repo.retirar(meta.id, centavos);
    } on MetaException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.mensaje)));
      }
    }
    ref.invalidate(metasProvider);
  }
}

class _FilaMeta extends StatelessWidget {
  const _FilaMeta({
    required this.meta,
    required this.onMover,
    required this.onEditar,
  });

  final Meta meta;
  final VoidCallback onMover;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onMover,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        meta.completada ? Icons.check_circle : Icons.savings_outlined,
        color: kLima,
      ),
      title: Text(meta.nombre),
      trailing: IconButton(
        tooltip: 'Editar meta',
        onPressed: onEditar,
        icon: const Icon(Icons.edit_outlined, color: kMuted),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 6),
          LinearProgressIndicator(value: meta.progreso, minHeight: 6),
          const SizedBox(height: 4),
          Text(
            '${formatQuetzales(meta.ahorradoCentavos)} de '
            '${formatQuetzales(meta.objetivoCentavos)}',
            style: const TextStyle(fontSize: 12, color: kMuted),
          ),
        ],
      ),
    );
  }
}
