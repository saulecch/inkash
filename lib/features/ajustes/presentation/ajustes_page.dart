import 'package:flutter/material.dart';
import 'package:inkash/features/categorias/presentation/categorias_page.dart';
import 'package:inkash/features/cuentas/presentation/cuentas_page.dart';
import 'package:inkash/theme.dart';

// s16-02: primera versión de Ajustes, con la gestión de datos.
// (El perfil, el límite mensual y el diseño final llegan en S17.)
class AjustesPage extends StatelessWidget {
  const AjustesPage({super.key});

  @override
  Widget build(BuildContext context) {
    void abrir(Widget pagina) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => pagina));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Ajustes', style: TextStyle(fontSize: 20)),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Cuentas'),
            subtitle: const Text(
              'Efectivo, bancos, tarjetas y saldos iniciales',
            ),
            trailing: const Icon(Icons.chevron_right, color: kMuted),
            onTap: () => abrir(const CuentasPage()),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Categorías'),
            subtitle: const Text('Crear, renombrar y archivar'),
            trailing: const Icon(Icons.chevron_right, color: kMuted),
            onTap: () => abrir(const CategoriasPage()),
          ),
        ],
      ),
    );
  }
}
