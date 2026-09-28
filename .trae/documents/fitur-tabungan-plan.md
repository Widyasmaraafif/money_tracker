# Rencana Fitur Tabungan (Saving Goals)

## Ringkasan
Tambahkan fitur Tabungan model Target/Goals mengikuti pola Budget yang sudah ada. Setiap tabungan punya nama, target nominal, terkumpul, deadline opsional. Aksi setor dan tarik mengubah `currentAmount` sekaligus mencatat transaksi otomatis di Beranda (setor = `expense`, tarik = `income`) agar saldo dan statistik ikut berubah.

Keputusan user:
- Model: Target / Goals (bukan dompet, bukan celengan tunggal).
- Keterkaitan data: Ya, catat otomatis sebagai transaksi.

## Analisis Kondisi Saat Ini
- Entry point + DI: [main.dart](file:///d:/2026/flutter/money_tracker/lib/main.dart) — `Hive.registerAdapter`, `Hive.openBox`, `MultiBlocProvider` (`TransactionCubit`, `RecurringCubit`, `BudgetCubit`), tema M3 + PlusJakartaSans.
- Penyimpanan: [hive_service.dart](file:///d:/2026/flutter/money_tracker/lib/services/hive_service.dart) — box `transactions`, `recurring_transactions`, `budgets`; pola `getAll/add/deleteAt/putAt` dengan try/catch + `debugPrint`. Operasi berbasis index box.
- Model referensi: [budget_model.dart](file:///d:/2026/flutter/money_tracker/lib/models/budget_model.dart) (`@HiveType(typeId: 2)`, logika `spent/progress` di dalam model) dan [transaction_model.dart](file:///d:/2026/flutter/money_tracker/lib/models/transaction_model.dart) (`typeId: 0`, field `title/amount/type/date/category/paymentMethod`).
- TypeId terpakai: 0 = Transaction, 1 = Recurring, 2 = Budget, 3 = RecurrenceType. TypeId 4 bebas untuk model baru.
- Cubit referensi: [budget_cubit.dart](file:///d:/2026/flutter/money_tracker/lib/blocs/budget_cubit.dart) — `load/loadForMonth/add/update/delete/indexOf`; UI resolve index asli via `indexOf` sebelum `delete/update`.
- UI referensi: [budgets_page.dart](file:///d:/2026/flutter/money_tracker/lib/views/budgets_page.dart) — pola list + FAB + dialog hapus + navigasi `AddBudgetPage` dengan `(object, index)`; [home_page.dart](file:///d:/2026/flutter/money_tracker/lib/views/home_page.dart) — AppBar actions (Rutin, Anggaran, Statistik), `RefreshIndicator` reload 3 cubit, `BlocBuilder` untuk list.
- Belum ada: model tabungan, box tabungan, cubit tabungan, halaman tabungan, kategori "Tabungan".

## Perubahan yang Diusulkan

### 1. `lib/models/saving_goal_model.dart` (baru) + generate `saving_goal_model.g.dart`
- Apa: `SavingGoalModel extends HiveObject`, `@HiveType(typeId: 4)`.
- Field: `name: String` (HiveField 0), `targetAmount: double` (1), `currentAmount: double` default 0 (2), `deadline: DateTime?` (3), `note: String?` (4), `createdAt: DateTime` (5), `isArchived: bool` default false (6).
- Method domain (meniru BudgetModel): `progress` (0.0–bisa >1.0, guard `target<=0`), `remaining`, `isCompleted` (`current >= target`), `deposit(amount)`, `withdraw(amount)` dengan validasi `amount>0` dan tarik tidak melebihi saldo.
- Kenapa: satu sumber kebenaran progress, UI tinggal baca.
- Cara: tulis manual + `part 'saving_goal_model.g.dart'`; jalankan `dart run build_runner build --delete-conflicting-outputs`.

### 2. `lib/services/hive_service.dart` (edit)
- Apa: tambah `savingBox` getter (`Hive.box<SavingGoalModel>('savings')`) + `getAllSavings/addSaving/updateSaving/deleteSaving` meniru pola budget (try/catch, index-based).
- Kenapa: konsisten dengan pola penyimpanan yang ada.
- Cara: tambah import model baru, salin struktur method budget.

### 3. `lib/blocs/saving_cubit.dart` (baru)
- Apa: `SavingCubit extends Cubit<List<SavingGoalModel>>` dengan `load/add/update/delete/indexOf` meniru `BudgetCubit`.
- Tambahan: `deposit(index, amount, {paymentMethod})` dan `withdraw(index, amount, {paymentMethod})` — update `currentAmount` via `HiveObject.save()` atau `updateSaving`, lalu return goal agar caller bisa catat transaksi. Jangan catat transaksi di dalam cubit (hindari dependensi antar-cubit); pencatatan dilakukan di UI layer dengan `TransactionCubit`.
- Kenapa: pisahkan state tabungan vs transaksi, ikuti SRP cubit yang ada.

### 4. `lib/utils/categories.dart` (edit, cek dulu)
- Apa: tambah kategori `Tabungan` ke daftar expense/income (atau minimal pastikan `getAll` mengenalnya) agar transaksi otomatis setor/tarik bisa difilter statistik.
- Kenapa: transaksi setor (`expense`, kategori `Tabungan`, judul `Setor ke {nama}`) dan tarik (`income`, kategori `Tabungan`, judul `Tarik dari {nama}`) tetap masuk agregasi yang benar.
- Cara: tambah string konstanta, bukan ubah API yang ada.

### 5. `lib/widgets/saving_item.dart` (baru)
- Apa: kartu meniru `budget_item.dart` — nama, deadline, `current/target` format rupiah, progress bar, status (Terkumpul/Sisa X/Hampir tercapai), tombol cepat Setor/Tarik.
- Kenapa: konsistensi visual list.

### 6. `lib/views/savings_page.dart` (baru)
- Apa: list semua goal (filter sembunyikan `isArchived` atau tab Selesai), empty state meniru BudgetsPage, tap → edit, aksi hapus via dialog, FAB → tambah.
- Deposit/withdraw: bottom sheet/dialog input nominal (pakai `CurrencyInputFormatter` + `parseAmount` dari `currency_formatter.dart`) + pilih `paymentMethod` (cash/bank); simpan → `SavingCubit.deposit/withdraw` + `TransactionCubit.add(TransactionModel(...))`.
- Kenapa: alur setor/tarik selalu atomis di UI (dua tulis, dua load).

### 7. `lib/views/add_saving_page.dart` (baru)
- Apa: form meniru `add_budget_page.dart` — nama, target (currency formatter + validator `>0`), deadline opsional (`showDatePicker`, validasi tidak sebelum hari ini), catatan opsional. Mode tambah vs edit via `(goal, index)` opsional.
- Kenapa: konsistensi UX form.

### 8. `lib/views/home_page.dart` (edit)
- Apa: tambah `IconButton` Tabungan (`savings_rounded` / `account_balance_wallet`) di AppBar actions → `SavingsPage`; tambah `SavingCubit.load()` di `onRefresh` RefreshIndicator.
- Kenapa: entry point setara Anggaran/Rutin.

### 9. `lib/main.dart` (edit)
- Apa: `registerAdapter(SavingGoalModelAdapter())`, `openBox<SavingGoalModel>('savings')` di `Future.wait`, tambah `BlocProvider(SavingCubit(..)..load())`.
- Kenapa: inisialisasi sejajar box lain, first-frame tetap cepat (open paralel).

## Asumsi & Keputusan
- Setor = transaksi `expense` kategori `Tabungan`, metode sesuai pilihan user saat setor; tarik = `income` kategori `Tabungan`. Ini mengurangi/menambah saldo kas sesuai permintaan "catat otomatis".
- Tidak ada transfer antar-goal pada versi ini; hanya setor dari kas dan tarik ke kas.
- Hapus goal tidak menghapus transaksi yang pernah dicatat (riwayat keuangan tetap utuh); hanya goal-nya yang dihapus.
- `deadline` opsional; tidak ada notifikasi deadline pada versi ini (bisa fase 2 pakai `NotificationService` yang sudah ada).
- Validasi: setor `>0`; tarik `>0` dan `<= currentAmount`; target `>0`.
- Tidak ubah typeId lama; pakai typeId 4 agar box lama aman.

## Langkah Verifikasi
1. `dart run build_runner build --delete-conflicting-outputs` sukses, `saving_goal_model.g.dart` terbentuk.
2. `flutter analyze` bersih (tidak ada error).
3. Manual: tambah goal → muncul di list dengan progress 0%; setor 2x → progress naik + 2 transaksi expense muncul di Beranda; tarik → progress turun + 1 transaksi income muncul; edit goal; hapus goal (riwayat transaksi tetap ada); pull-to-refresh di Home tidak error; restart app data tabungan persist.
4. Edge: tarik melebihi saldo ditolak dengan SnackBar; target 0 ditolak validator; deadline sebelum hari ini ditolak.
