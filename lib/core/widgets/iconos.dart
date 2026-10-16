import 'package:flutter/material.dart';

// El icono se guarda en SQLite como TEXTO (SQLite no sabe qué es un IconData).
// Este catálogo es la única traducción texto -> icono de la app, y también
// la lista que ofrecen los selectores de icono (cuentas y categorías).
const iconosDisponibles = <String, IconData>{
  // Cuentas
  'payments': Icons.payments_outlined,
  'account_balance': Icons.account_balance_outlined,
  'credit_card': Icons.credit_card,
  'savings': Icons.savings_outlined,
  'wallet': Icons.account_balance_wallet_outlined,
  // Categorías
  'directions_bus': Icons.directions_bus,
  'shopping_cart': Icons.shopping_cart,
  'arrow_upward': Icons.arrow_upward,
  'local_cafe': Icons.local_cafe,
  'movie': Icons.movie_outlined,
  'bolt': Icons.bolt,
  'home': Icons.home,
  'restaurant': Icons.restaurant,
  'school': Icons.school_outlined,
  'health': Icons.local_hospital_outlined,
  'pets': Icons.pets,
  'phone': Icons.phone_iphone,
  'gift': Icons.card_giftcard,
  'work': Icons.work_outline,
  'attach_money': Icons.attach_money,
};

IconData iconoDe(String nombre) =>
    iconosDisponibles[nombre] ?? Icons.attach_money;
