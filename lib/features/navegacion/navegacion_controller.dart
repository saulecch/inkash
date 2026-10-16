import 'package:flutter_riverpod/flutter_riverpod.dart';

// Las pestañas que son PANTALLAS. "Agregar" no está aquí: no es un lugar,
// es una acción (abre el formulario encima de la pestaña actual).
enum Pestana { inicio, presupuesto, historial, ajustes }

// La pestaña activa también es estado de la app. Al ponerla en un provider,
// cualquier pantalla puede navegar (p. ej. "Ver todo" en el Inicio) sin
// recibir callbacks por constructor.
final navegacionProvider = NotifierProvider<NavegacionController, Pestana>(
  NavegacionController.new,
);

class NavegacionController extends Notifier<Pestana> {
  @override
  Pestana build() => Pestana.inicio;

  // Asignar `state` notifica a todos los que hacen ref.watch.
  void ir(Pestana pestana) => state = pestana;
}
