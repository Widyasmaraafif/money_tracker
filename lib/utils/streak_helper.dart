import '../models/transaction_model.dart';

/// Hasil perhitungan streak pencatatan harian.
class StreakInfo {
  /// Jumlah hari beruntun mencatat (termasuk hari ini jika sudah catat).
  final int currentStreak;
  final bool loggedToday;

  /// 7 tanggal terakhir, urut dari paling lama ke hari ini.
  final List<DateTime> last7Dates;

  /// Apakah tiap tanggal di [last7Dates] ada pencatatan.
  final List<bool> weekLogged;

  const StreakInfo({
    required this.currentStreak,
    required this.loggedToday,
    required this.last7Dates,
    required this.weekLogged,
  });
}

String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

/// Streak = hari beruntun yang ada minimal 1 transaksi.
/// Kalau hari ini belum catat tapi kemarin catat, streak lama masih
/// dipertahankan (belum putus) agar bisa dilanjutkan hari ini.
StreakInfo computeStreak(List<TransactionModel> transactions) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final loggedDays = <String>{};
  for (final t in transactions) {
    final d = t.date;
    if (d.isAfter(DateTime(today.year, today.month, today.day, 23, 59, 59))) {
      continue; // Transaksi bertanggal masa depan tidak dihitung.
    }
    loggedDays.add(_dayKey(d));
  }

  final loggedToday = loggedDays.contains(_dayKey(today));

  var streak = 0;
  var cursor = loggedToday ? today : today.subtract(const Duration(days: 1));
  while (loggedDays.contains(_dayKey(cursor))) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  final last7Dates = List.generate(
    7,
    (i) => today.subtract(Duration(days: 6 - i)),
  );
  final weekLogged = last7Dates
      .map((d) => loggedDays.contains(_dayKey(d)))
      .toList();

  return StreakInfo(
    currentStreak: streak,
    loggedToday: loggedToday,
    last7Dates: last7Dates,
    weekLogged: weekLogged,
  );
}
