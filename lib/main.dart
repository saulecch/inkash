import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// Paleta del design system del prototipo (broadsheet dark):
const kFondo = Color(0xFF0E120C);
const kSuperficie = Color(0xFF181E14);
const kBorde = Color(0xFF2A3222);
const kTexto = Color(0xFFF1F4EA);
const kMuted = Color(0xFF8F9C80);
const kLima = Color(0xFFC8F54E); // --color-accent
const kIconoFondo = Color(0xFF37491C); // --color-accent-300

const kFig = TextStyle(fontFamily: 'monospace'); // cifras (Azeret Mono)

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inkash',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kFondo,
      ),
      home: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: EdgeInsets.all(16.0),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text('Hola, Kevin'), Text('Julio 2026')],
              ),
              const SizedBox(height: 22),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('TE QUEDAN DISPONIBLES', style: TextStyle(fontSize: 11)),
                  SizedBox(height: 6),
                  Text('Q2,796.50', style: TextStyle(fontSize: 52)),
                  SizedBox(height: 16),
                  LinearProgressIndicator(value: 0.57),
                  SizedBox(height: 7),
                  Text(
                    'Has usado Q3,703.50 de Q6,500.00',
                    style: TextStyle(fontSize: 12),
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
                children: const [
                  Text('Últimos movimientos', style: TextStyle(fontSize: 20)),
                  Spacer(),
                  Text('Ver todo', style: TextStyle(fontSize: 13)),
                ],
              ),
              filaMovimiento(
                Icons.directions_bus,
                'Uber al trabajo',
                'Transporte · Tarjeta',
                '− Q38.00',
                'Hoy',
              ),
              filaMovimiento(
                Icons.shopping_cart,
                'Súper La Torre',
                'Súper y comida · Tarjeta',
                '− Q285.50',
                'Ayer',
              ),
              filaMovimiento(
                Icons.arrow_upward,
                'Salario quincena',
                'Ingreso · Banco',
                '+ Q4,200.00',
                'Ayer',
              ),
              filaMovimiento(
                Icons.local_cafe,
                'Café con Ana',
                'Entretenimiento · Efectivo',
                '− Q65.00',
                'Ayer',
              ),
              filaMovimiento(
                Icons.bolt,
                'Recibo de luz (EEGSA)',
                'Servicios · Banco',
                '− Q420.00',
                'Lun 20',
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
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
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}

Widget filaMovimiento(
  IconData icon,
  String title,
  String subtitle,
  String amount,
  String date,
) {
  return ListTile(
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [Text(amount), Text(date)],
    ),
  );
}

Widget tarjetaHero(String title, String body) {
  return Expanded(
    child: Container(
      color: kSuperficie,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11)),
          SizedBox(height: 2),
          Text(body, style: TextStyle(fontSize: 19)),
        ],
      ),
    ),
  );
}
