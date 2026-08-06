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
        colorScheme: ColorScheme.fromSeed(
          seedColor: kLima,
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(
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
                children: const [
                  Text(
                    'TE QUEDAN DISPONIBLES',
                    style: TextStyle(fontSize: 11, color: kLima),
                  ),
                  Text(
                    'Q2,796.50',
                    style: TextStyle(
                      fontSize: 52,
                      color: kTexto,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: 0.57,
                    color: kLima,
                    minHeight: 8.0,
                    // backgroundColor: Colors.blue,
                  ),
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
