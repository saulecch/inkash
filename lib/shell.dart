import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inkash/core/widgets/proximamente.dart';
import 'package:inkash/features/ajustes/presentation/ajustes_page.dart';
import 'package:inkash/features/historial/historial_page.dart';
import 'package:inkash/features/home/presentation/widgets/abrir_formulario_movimiento.dart';
import 'package:inkash/features/navegacion/navegacion_controller.dart';
import 'package:inkash/home.dart';
import 'package:inkash/theme.dart';

// El "cascarón" de la app: la barra inferior y las pantallas de cada pestaña.
// Antes la barra vivía dentro de HomePage, así que solo existía el Inicio.
class InkashShell extends ConsumerWidget {
  const InkashShell({super.key});

  // Orden de la barra: Inicio · Presupuesto · (+) · Historial · Ajustes.
  // El índice 2 es el botón Agregar, que no tiene pantalla.
  static const _indiceAgregar = 2;
  static const _pestanasPorIndice = {
    0: Pestana.inicio,
    1: Pestana.presupuesto,
    3: Pestana.historial,
    4: Pestana.ajustes,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actual = ref.watch(navegacionProvider);

    return Scaffold(
      // IndexedStack construye TODAS las pantallas y muestra una. Cada pestaña
      // conserva su scroll y sus filtros al cambiar de pestaña.
      body: IndexedStack(
        index: actual.index,
        children: const [
          HomePage(),
          ProximamentePage(titulo: 'Presupuesto', icono: Icons.bar_chart),
          HistorialPage(),
          AjustesPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _pestanasPorIndice.entries
            .firstWhere((e) => e.value == actual)
            .key,
        onTap: (index) {
          if (index == _indiceAgregar) {
            abrirFormularioMovimiento(context, ref);
            return;
          }
          ref.read(navegacionProvider.notifier).ir(_pestanasPorIndice[index]!);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kLima,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Presupuesto',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle, size: 34),
            label: 'Agregar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Historial',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
