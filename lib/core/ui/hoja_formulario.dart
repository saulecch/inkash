import 'package:flutter/material.dart';
import 'package:inkash/theme.dart';

/// Cuerpo común de las hojas inferiores con formulario: título, campos y
/// botones, con el espacio del teclado ya resuelto. Antes cada hoja repetía
/// el mismo Padding con `viewInsets` y su propio título.
class HojaFormulario extends StatelessWidget {
  const HojaFormulario({
    required this.titulo,
    required this.children,
    this.descripcion,
    super.key,
  });

  final String titulo;
  final String? descripcion;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final texto = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Espacio.xl,
        0,
        Espacio.xl,
        Espacio.xl + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: texto.titleLarge),
          if (descripcion != null) ...[
            const SizedBox(height: Espacio.xs),
            Text(descripcion!, style: texto.bodySmall),
          ],
          const SizedBox(height: Espacio.xl),
          ...children,
        ],
      ),
    );
  }
}

/// Abre una hoja inferior con el estilo del tema (asa, esquinas, fondo).
Future<T?> mostrarHoja<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: builder,
  );
}
