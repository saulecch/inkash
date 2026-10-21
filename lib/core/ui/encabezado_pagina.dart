import 'package:flutter/material.dart';
import 'package:inkash/theme.dart';

/// Encabezado común de las pestañas: título grande alineado a la izquierda,
/// una línea de contexto opcional y, si hace falta, una acción a la derecha.
/// Antes cada pantalla inventaba el suyo (tamaños 18, 20, centrado…).
class EncabezadoPagina extends StatelessWidget {
  const EncabezadoPagina({
    required this.titulo,
    this.subtitulo,
    this.accion,
    super.key,
  });

  final String titulo;
  final String? subtitulo;
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Espacio.l,
        Espacio.xl,
        Espacio.l,
        Espacio.l,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: texto.headlineSmall),
                if (subtitulo != null) ...[
                  const SizedBox(height: Espacio.xs),
                  Text(subtitulo!, style: texto.bodySmall),
                ],
              ],
            ),
          ),
          ?accion,
        ],
      ),
    );
  }
}
