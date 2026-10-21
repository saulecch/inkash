import 'package:flutter/material.dart';
import 'package:inkash/core/ui/encabezado_pagina.dart';
import 'package:inkash/core/ui/seccion.dart';
import 'package:inkash/features/categorias/presentation/categorias_page.dart';
import 'package:inkash/features/cuentas/presentation/cuentas_page.dart';

// s16-02: primera versión de Ajustes, con la gestión de datos.
// s17-01: mismo encabezado y secciones que el resto de la app.
// (El perfil y el límite mensual llegan en s17-02.)
class AjustesPage extends StatelessWidget {
  const AjustesPage({super.key});

  @override
  Widget build(BuildContext context) {
    void abrir(Widget pagina) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => pagina));

    return SafeArea(
      child: ListView(
        children: [
          const EncabezadoPagina(titulo: 'Ajustes'),
          Seccion(
            titulo: 'Tus datos',
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text('Cuentas'),
                subtitle: const Text('Efectivo, bancos, tarjetas y saldos'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => abrir(const CuentasPage()),
              ),
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('Categorías'),
                subtitle: const Text('Crear, renombrar y archivar'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => abrir(const CategoriasPage()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
