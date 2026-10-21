import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/features/categorias/domain/categoria.dart';
import 'package:inkash/features/categorias/presentation/categorias_page.dart';
import 'package:inkash/features/categorias/presentation/categorias_provider.dart';
import 'package:inkash/features/cuentas/domain/cuenta.dart';
import 'package:inkash/features/cuentas/presentation/cuentas_provider.dart';
import 'package:inkash/features/home/domain/movimiento.dart';
import 'package:inkash/features/home/domain/movimiento_eliminado.dart';
import 'package:inkash/features/home/presentation/controllers/home_controller.dart';
import 'package:inkash/features/home/presentation/widgets/movimiento_bottom_sheet.dart';
import 'package:inkash/theme.dart';

/// Abre el formulario para crear (editar == null) o editar un movimiento.
/// s16-03: antes vivía dentro del shell; ahora lo usan el botón (+), el
/// Inicio y el Historial (tocar un movimiento).
Future<void> abrirFormularioMovimiento(
  BuildContext context,
  WidgetRef ref, {
  Movimiento? editar,
}) async {
  // Las cuentas y categorías se piden ANTES de abrir. Si fallan, el
  // formulario abre igual: registrar un gasto no debe bloquearse.
  final cuentas = await ref
      .read(cuentasProvider.future)
      .catchError((_) => <Cuenta>[]);
  final categorias = await ref
      .read(categoriasProvider.future)
      .catchError((_) => <Categoria>[]);
  if (!context.mounted) return;

  final controller = ref.read(homeControllerProvider.notifier);
  MovimientoEliminado? eliminado;

  // El sheet hace pop('guardado') o pop('eliminado').
  final resultado = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: kSuperficie,
    builder: (_) => MovimientoBottomSheet(
      inicial: editar,
      cuentas: cuentas,
      categorias: categorias,
      onGuardar: (nuevo) => editar == null
          ? controller.guardarMovimiento(nuevo)
          : controller.actualizarMovimiento(editar.id, nuevo),
      onEliminar: editar == null
          ? null
          : () async => eliminado = await controller.eliminar(editar.id),
      // Crear la categoría y devolverla ya con su id de la base.
      onNuevaCategoria: (tipo) async {
        final nombre = await abrirFormularioCategoria(
          context,
          ref,
          tipoInicial: tipo,
        );
        if (nombre == null) return null;
        final lista = await ref.read(categoriasProvider.future);
        return lista.firstWhere((c) => c.nombre == nombre);
      },
    ),
  );
  if (resultado == null || !context.mounted) return;

  final borrado = eliminado;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(switch (resultado) {
        'eliminado' => 'Movimiento eliminado',
        _ when editar != null => 'Cambios guardados',
        _ => 'Movimiento guardado',
      }),
      action: borrado == null
          ? null
          : SnackBarAction(
              label: 'Deshacer',
              onPressed: () => controller.deshacer(borrado),
            ),
    ),
  );
}
