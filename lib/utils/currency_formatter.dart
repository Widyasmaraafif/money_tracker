import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Cached formats — NumberFormat construction is expensive, so reuse singletons.
final NumberFormat rupiahFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

final NumberFormat plainAmountFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: '',
  decimalDigits: 0,
);

final DateFormat dayMonthYearId = DateFormat('dd MMM yyyy', 'id_ID');
final DateFormat fullDateId = DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
final DateFormat monthYearId = DateFormat('MMMM yyyy', 'id_ID');

String formatRupiah(num amount) => rupiahFormat.format(amount);

/// Short digits without symbol/currency, e.g. 5000000 -> 5.000.000
String formatPlain(num amount) => plainAmountFormat.format(amount).trim();

/// Formats numeric input into Indonesian thousand-separated groups
/// while the user types, e.g. `5000000` -> `5.000.000`.
class CurrencyInputFormatter extends TextInputFormatter {
  NumberFormat get _formatter => plainAmountFormat;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final value = int.tryParse(digits) ?? 0;
    final formatted = _formatter.format(value).trim();

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formats a double as Indonesian grouped digits without currency symbol.
String formatAmount(double amount) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );
  return formatter.format(amount).trim();
}

/// Parses a formatted amount string (e.g. `5.000.000`) back to a double.
double parseAmount(String text) {
  final digits = text.replaceAll(RegExp(r'[^0-9]'), '');
  return double.tryParse(digits) ?? 0.0;
}
