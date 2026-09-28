import 'package:flutter/material.dart';

/// Dompet yang didukung aplikasi. Saat ini Tunai & Bank,
/// dibuat terpusat agar label konsisten di semua halaman.
class Wallets {
  static const String cash = 'cash';
  static const String bank = 'bank';

  static const List<String> all = [cash, bank];

  static String label(String value) {
    switch (value) {
      case cash:
        return 'Tunai';
      case bank:
        return 'Bank';
      default:
        return value;
    }
  }

  static IconData icon(String value) {
    switch (value) {
      case cash:
        return Icons.wallet_rounded;
      case bank:
        return Icons.account_balance_rounded;
      default:
        return Icons.account_balance_wallet_outlined;
    }
  }

  /// Saldo per dompet. Transfer hanya memindahkan saldo,
  /// tidak mengubah total maupun income/expense.
  static Map<String, double> balances(List<dynamic> transactions) {
    double cashBalance = 0;
    double bankBalance = 0;
    for (final trx in transactions) {
      final String type = trx.type as String;
      final double amount = (trx.amount as num).toDouble();
      final String from = trx.paymentMethod as String;
      if (type == 'transfer') {
        final String? dest = trx.toPaymentMethod as String?;
        if (dest == null) continue;
        if (from == cash) {
          cashBalance -= amount;
        } else {
          bankBalance -= amount;
        }
        if (dest == cash) {
          cashBalance += amount;
        } else {
          bankBalance += amount;
        }
        continue;
      }
      final signed = type == 'income' ? amount : -amount;
      if (from == cash) {
        cashBalance += signed;
      } else {
        bankBalance += signed;
      }
    }
    return {cash: cashBalance, bank: bankBalance};
  }
}
