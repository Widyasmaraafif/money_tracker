import 'package:flutter/material.dart';

class TransactionCategory {
  final String name;
  final IconData icon;
  final Color color;

  const TransactionCategory({
    required this.name,
    required this.icon,
    required this.color,
  });

  static const List<TransactionCategory> expenseCategories = [
    TransactionCategory(
      name: 'Makanan & Minuman',
      icon: Icons.fastfood_rounded,
      color: Colors.orange,
    ),
    TransactionCategory(
      name: 'Transportasi',
      icon: Icons.directions_bus_rounded,
      color: Colors.blue,
    ),
    TransactionCategory(
      name: 'Belanja',
      icon: Icons.shopping_bag_rounded,
      color: Colors.pink,
    ),
    TransactionCategory(
      name: 'Hiburan',
      icon: Icons.movie_rounded,
      color: Colors.purple,
    ),
    TransactionCategory(
      name: 'Tagihan',
      icon: Icons.receipt_long_rounded,
      color: Colors.red,
    ),
    TransactionCategory(
      name: 'Kesehatan',
      icon: Icons.medical_services_rounded,
      color: Colors.teal,
    ),
    TransactionCategory(
      name: 'Pendidikan',
      icon: Icons.school_rounded,
      color: Colors.indigo,
    ),
    TransactionCategory(
      name: 'Lainnya',
      icon: Icons.category_rounded,
      color: Colors.grey,
    ),
  ];

  static const List<TransactionCategory> incomeCategories = [
    TransactionCategory(
      name: 'Gaji',
      icon: Icons.payments_rounded,
      color: Colors.green,
    ),
    TransactionCategory(
      name: 'Investasi',
      icon: Icons.trending_up_rounded,
      color: Colors.blueAccent,
    ),
    TransactionCategory(
      name: 'Hadiah',
      icon: Icons.card_giftcard_rounded,
      color: Colors.amber,
    ),
    TransactionCategory(
      name: 'Lainnya',
      icon: Icons.category_rounded,
      color: Colors.grey,
    ),
  ];

  static List<TransactionCategory> getAll(String type) {
    return type == 'income' ? incomeCategories : expenseCategories;
  }

  static TransactionCategory getByName(String name) {
    return [...expenseCategories, ...incomeCategories].firstWhere(
      (cat) => cat.name == name,
      orElse: () => const TransactionCategory(
        name: 'Lainnya',
        icon: Icons.category_rounded,
        color: Colors.grey,
      ),
    );
  }
}
