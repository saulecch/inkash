import 'package:flutter/material.dart';
import 'package:inkash/features/home/presentation/controllers/home_controller.dart';
import 'package:inkash/theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({required this.controller, super.key});

  final MovimientosController controller;

  @override
  Widget build(BuildContext context) {
    // La pantalla recibe los resultados desde el controlador.
    final totalGastado = controller.totalGastadoCentavos;
    final saldoDisponible = controller.saldoDisponibleCentavos;

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
                  _formatQuetzales(saldoDisponible),
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
                  'Has usado ${_formatQuetzales(totalGastado)} '
                  'de ${_formatQuetzales(controller.limiteMensualCentavos)}',
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
            filaMovimiento(
              icon: Icons.directions_bus,
              title: 'Uber al trabajo',
              subtitle: 'Transporte · Tarjeta',
              amount: '− Q38.00',
              date: 'Hoy',
            ),
            filaMovimiento(
              icon: Icons.shopping_cart,
              title: 'Súper La Torre',
              subtitle: 'Súper y comida · Tarjeta',
              amount: '− Q285.50',
              date: 'Ayer',
            ),
            filaMovimiento(
              icon: Icons.arrow_upward,
              title: 'Salario quincena',
              subtitle: 'Ingreso · Banco',
              amount: '+ Q4,200.00',
              date: 'Ayer',
              isIncome: true,
            ),
            filaMovimiento(
              icon: Icons.local_cafe,
              title: 'Café con Ana',
              subtitle: 'Entretenimiento · Efectivo',
              amount: '− Q65.00',
              date: 'Ayer',
            ),
            filaMovimiento(
              icon: Icons.bolt,
              title: 'Recibo de luz (EEGSA)',
              subtitle: 'Servicios · Banco',
              amount: '− Q420.00',
              date: 'Lun 20',
            ),
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

  Widget filaMovimiento({
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required String date,
    bool isIncome = false,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: kIconoFondo,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(icon, color: kLima),
      ),
      title: Text(title, style: TextStyle(color: kTexto)),
      subtitle: Text(subtitle, style: TextStyle(color: kMuted)),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            amount,
            style: TextStyle(fontSize: 13, color: isIncome ? kLima : kTexto),
          ),
          Text(date, style: TextStyle(fontSize: 10, color: kMuted)),
        ],
      ),
    );
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

  String _formatQuetzales(int centavos) {
    // La UI convierte los centavos a un texto legible para el usuario.
    final entero = centavos ~/ 100;
    final decimales = (centavos % 100).toString().padLeft(2, '0');
    final miles = entero.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return 'Q$miles.$decimales';
  }
}
