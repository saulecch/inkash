import 'package:flutter/material.dart';
import 'package:inkash/theme.dart';

/// Pantalla o sección sin datos. Un vacío no es un error: es una invitación
/// a hacer algo, así que casi siempre lleva una acción.
class EstadoVacio extends StatelessWidget {
  const EstadoVacio({
    required this.icono,
    required this.titulo,
    this.mensaje,
    this.accion,
    this.onAccion,
    super.key,
  });

  final IconData icono;
  final String titulo;
  final String? mensaje;
  final String? accion;
  final VoidCallback? onAccion;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Espacio.xxl,
        vertical: Espacio.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: kIconoFondo,
            child: Icon(icono, color: kLima),
          ),
          const SizedBox(height: Espacio.l),
          Text(titulo, style: texto.titleMedium, textAlign: TextAlign.center),
          if (mensaje != null) ...[
            const SizedBox(height: Espacio.xs),
            Text(mensaje!, style: texto.bodySmall, textAlign: TextAlign.center),
          ],
          if (accion != null) ...[
            const SizedBox(height: Espacio.l),
            FilledButton.tonal(onPressed: onAccion, child: Text(accion!)),
          ],
        ],
      ),
    );
  }
}
