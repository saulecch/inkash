import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/core/format/formato_moneda.dart';
import 'package:inkash/core/ui/encabezado_pagina.dart';
import 'package:inkash/core/ui/hoja_texto.dart';
import 'package:inkash/core/ui/seccion.dart';
import 'package:inkash/core/widgets/hoja_monto.dart';
import 'package:inkash/features/ajustes/domain/ajustes.dart';
import 'package:inkash/features/ajustes/presentation/ajustes_controller.dart';
import 'package:inkash/features/categorias/presentation/categorias_page.dart';
import 'package:inkash/features/cuentas/presentation/cuentas_page.dart';
import 'package:inkash/theme.dart';

// s17-02: Ajustes completo. Perfil arriba (quién usa la app), luego lo que
// se ajusta seguido (límite), la gestión de datos y, al final y separado,
// lo peligroso.
class AjustesPage extends ConsumerWidget {
  const AjustesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ajustes = ref.watch(ajustesProvider);
    return SafeArea(
      child: ajustes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(ajustesProvider),
            child: const Text('No pudimos leer los ajustes. Reintentar'),
          ),
        ),
        data: (a) => _Contenido(ajustes: a),
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.ajustes});

  final Ajustes ajustes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(ajustesProvider.notifier);
    final texto = Theme.of(context).textTheme;
    void abrir(Widget pagina) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => pagina));

    Future<void> editarNombre() async {
      final nombre = await pedirTexto(
        context,
        titulo: '¿Cómo te llamas?',
        descripcion: 'Lo usamos para saludarte en el Inicio.',
        inicial: ajustes.nombre,
        etiqueta: 'Tu nombre',
      );
      if (nombre != null) await controller.cambiarNombre(nombre);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: Espacio.xxl),
      children: [
        const EncabezadoPagina(titulo: 'Ajustes'),
        // Perfil: la inicial en grande y el nombre; tocar = editar.
        Seccion(
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(Espacio.l),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: kLima,
                foregroundColor: kFondo,
                child: Text(
                  ajustes.nombre.isEmpty
                      ? '?'
                      : ajustes.nombre.characters.first.toUpperCase(),
                  style: texto.titleLarge?.copyWith(color: kFondo),
                ),
              ),
              title: Text(
                ajustes.nombre.isEmpty ? 'Agrega tu nombre' : ajustes.nombre,
                style: texto.titleMedium,
              ),
              subtitle: const Text('Toca para cambiarlo'),
              trailing: const Icon(Icons.edit_outlined),
              onTap: editarNombre,
            ),
          ],
        ),
        Seccion(
          titulo: 'Este mes',
          children: [
            ListTile(
              leading: const Icon(Icons.speed),
              title: const Text('Límite mensual'),
              subtitle: const Text('Cuánto quieres gastar como máximo'),
              trailing: Text(
                formatQuetzales(ajustes.limiteMensualCentavos),
                style: texto.titleMedium?.copyWith(
                  color: kLima,
                  fontFeatures: kNumerosTabulares,
                ),
              ),
              onTap: () async {
                final respuesta = await pedirMonto(
                  context,
                  titulo: 'Límite mensual',
                  ayuda: 'El Inicio te dice cuánto te queda de este monto.',
                  inicialCentavos: ajustes.limiteMensualCentavos,
                );
                final centavos = respuesta?.centavos;
                if (centavos != null) await controller.cambiarLimite(centavos);
              },
            ),
          ],
        ),
        Seccion(
          titulo: 'Tus datos',
          children: [
            ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Cuentas'),
              subtitle: const Text('Efectivo, bancos, tarjetas y saldos'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => abrir(const CuentasPage()),
            ),
            ListTile(
              leading: const Icon(Icons.category_outlined),
              title: const Text('Categorías'),
              subtitle: const Text('Crear, renombrar y archivar'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => abrir(const CategoriasPage()),
            ),
          ],
        ),
        Seccion(
          children: [
            ListTile(
              leading: const Icon(Icons.delete_forever, color: kPeligro),
              title: const Text(
                'Borrar todos mis datos',
                style: TextStyle(color: kPeligro),
              ),
              subtitle: const Text('Movimientos, metas, límites y ajustes'),
              onTap: () => _confirmarBorrado(context, ref),
            ),
          ],
        ),
        Center(
          child: Text(
            'Inkash 0.9 · Proyecto de PDM, UMES 2026',
            style: texto.bodySmall,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmarBorrado(BuildContext context, WidgetRef ref) async {
    // Acción destructiva e irreversible: SIEMPRE confirmar, con el botón
    // peligroso explícito (no "Aceptar").
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar todos tus datos?'),
        content: const Text(
          'Se borran tus movimientos, metas, límites y ajustes. '
          'Las cuentas y categorías se quedan. No se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: kPeligro,
              minimumSize: const Size(0, 44),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar todo'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(ajustesProvider.notifier).borrarDatosDelUsuario();
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Datos borrados')));
    }
  }
}
