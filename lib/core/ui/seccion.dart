import 'package:flutter/material.dart';
import 'package:inkash/theme.dart';

/// Grupo de filas sobre una superficie, con título opcional encima.
/// Se usa en Ajustes, Cuentas y Categorías: misma forma = misma función.
class Seccion extends StatelessWidget {
  const Seccion({required this.children, this.titulo, super.key});

  final String? titulo;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Espacio.l, 0, Espacio.l, Espacio.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (titulo != null)
            Padding(
              padding: const EdgeInsets.only(
                left: Espacio.xs,
                bottom: Espacio.s,
              ),
              child: Text(
                titulo!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          Material(
            color: kSuperficie,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(Redondeo.tarjeta),
              side: const BorderSide(color: kBorde),
            ),
            clipBehavior: Clip.antiAlias, // el "ripple" respeta las esquinas
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(indent: 56),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
