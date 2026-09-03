import 'package:flutter/material.dart';
import 'package:inkash/core/format/formato_moneda.dart';
import 'package:inkash/features/home/domain/movimiento.dart';
import 'package:inkash/features/home/presentation/controllers/home_controller.dart';
import 'package:inkash/theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.controller, super.key});

  final MovimientosController controller;

  // La pantalla recibe los resultados desde el controlador.
  @override
  Widget build(BuildContext context) {
    final totalGastado = controller.totalGastadoCentavos;
    final saldoDisponible = controller.saldoDisponibleCentavos;
    final movimientos = controller.movimientos;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hola, Kevin'),
                Text('Julio 2026', style: TextStyle(color: kMuted)),
              ],
            ),
            const SizedBox(height: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TE QUEDAN DISPONIBLES',
                  style: TextStyle(fontSize: 11, color: kLima),
                ),
                Text(
                  formatQuetzales(saldoDisponible),
                  style: const TextStyle(
                    fontSize: 52,
                    color: kTexto,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: totalGastado / controller.limiteMensualCentavos,
                  color: kLima,
                  minHeight: 8.0,
                ),
                const SizedBox(height: 7),
                Text(
                  'Has usado ${formatQuetzales(totalGastado)} '
                  'de ${formatQuetzales(controller.limiteMensualCentavos)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                tarjetaHero('Cuentas', 'Q7,810.00'),
                const SizedBox(width: 12),
                tarjetaHero('Metas de ahorro', '3 activas'),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Text('Últimos movimientos', style: TextStyle(fontSize: 20)),
                Spacer(),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Ver todo',
                    style: TextStyle(fontSize: 13, color: kLima),
                  ),
                ),
              ],
            ),
            ...movimientos.map(filaMovimiento),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
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

  Widget filaMovimiento(Movimiento movimiento) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: kIconoFondo,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(_iconDataDe(movimiento.icono), color: kLima),
      ),
      title: Text(movimiento.titulo, style: TextStyle(color: kTexto)),
      subtitle: Text(
        movimiento.subtitulo,
        style: TextStyle(color: kMuted),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatQuetzales(movimiento.montoFirmadoCentavos),
            style: TextStyle(
              fontSize: 13,
              color: movimiento.esIngreso ? kLima : kTexto,
            ),
          ),
          Text(movimiento.fecha, style: TextStyle(fontSize: 10, color: kMuted)),
        ],
      ),
    );
  }

  // Convierte el nombre del icono (guardado como texto) a un IconData.
  IconData _iconDataDe(String nombre) {
    return switch (nombre) {
      'directions_bus' => Icons.directions_bus,
      'shopping_cart' => Icons.shopping_cart,
      'arrow_upward' => Icons.arrow_upward,
      'local_cafe' => Icons.local_cafe,
      'bolt' => Icons.bolt,
      'home' => Icons.home,
      _ => Icons.attach_money,
    };
  }

  Widget tarjetaHero(String title, String body) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: kSuperficie,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: kBorde),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 11, color: kMuted)),
            SizedBox(height: 2),
            Text(body, style: TextStyle(fontSize: 19)),
          ],
        ),
      ),
    );
  }
}
