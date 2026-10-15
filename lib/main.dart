import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  // ProviderScope reemplaza al ProviderContainer manual de S09: crea el
  // contenedor, lo entrega a todos los widgets y lo libera al cerrar.
  //
  // Ya no abrimos la base aquí con await: si fallara, la app no arrancaría.
  // Ahora la abre el primer provider que la necesita, y un error se ve en
  // pantalla con un botón "Reintentar".
  runApp(const ProviderScope(child: InkashApp()));
}
