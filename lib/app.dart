import 'package:flutter/material.dart';
import 'package:inkash/shell.dart';
import 'package:inkash/theme.dart';

// Ya no recibe el controlador: cada pantalla lo pide con ref.watch.
// s15-01: la pantalla raíz es el cascarón con las pestañas.
class InkashApp extends StatelessWidget {
  const InkashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Inkash',
      theme: buildInkashTheme(),
      home: const InkashShell(),
    );
  }
}
