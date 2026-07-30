import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inkash',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
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
                  Expanded(
                    child: Container(
                      color: Colors.grey.shade300,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Cuentas', style: TextStyle(fontSize: 11)),
                          SizedBox(height: 2),
                          Text('Q7,810.00', style: TextStyle(fontSize: 19)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      color: Colors.grey.shade300,
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Metas de ahorro',
                            style: TextStyle(fontSize: 11),
                          ),
                          SizedBox(height: 2),
                          Text('3 activas', style: TextStyle(fontSize: 19)),
                        ],
                      ),
                    ),
                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}
