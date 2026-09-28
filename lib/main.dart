import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_tracker/blocs/transaction_cubit.dart';
import 'package:money_tracker/blocs/recurring_cubit.dart';
import 'package:money_tracker/blocs/budget_cubit.dart';
import 'package:money_tracker/blocs/saving_cubit.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/models/recurring_transaction_model.dart';
import 'package:money_tracker/models/budget_model.dart';
import 'package:money_tracker/models/saving_goal_model.dart';
import 'package:money_tracker/services/hive_service.dart';
import 'package:money_tracker/services/notification_service.dart';
import 'package:money_tracker/views/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Parallelize independent init work: locale data + Hive setup.
  await Future.wait([
    initializeDateFormatting('id_ID', null),
    Hive.initFlutter(),
  ]);
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(RecurrenceTypeAdapter());
  Hive.registerAdapter(RecurringTransactionModelAdapter());
  Hive.registerAdapter(BudgetModelAdapter());
  Hive.registerAdapter(SavingGoalModelAdapter());

  // Open all boxes concurrently instead of sequentially.
  await Future.wait([
    Hive.openBox<TransactionModel>('transactions'),
    Hive.openBox<RecurringTransactionModel>('recurring_transactions'),
    Hive.openBox<BudgetModel>('budgets'),
    Hive.openBox<SavingGoalModel>('savings'),
  ]);

  // Render first frame ASAP; notifications + recurring catch-up run after.
  runApp(const MyApp());

  // Non-blocking: don't delay first frame on notification permission dialogs.
  NotificationService.initialize().ignore();
  _processDueRecurring();
}

/// Catch up overdue recurring transactions in background (batched writes).
Future<void> _processDueRecurring() async {
  try {
    final hiveService = HiveService();
    final box = hiveService.recurringBox;
    final now = DateTime.now();
    final dueKeys = <int>[];
    final newTransactions = <TransactionModel>[];
    final reminders = <Future<void>>[];

    for (final key in box.keys.cast<int>()) {
      final trx = box.get(key);
      if (trx == null || !trx.isActive || !trx.nextOccurrence.isBefore(now)) {
        continue;
      }
      // Catch up all missed occurrences, not just one.
      var guard = 0;
      while (trx.isActive &&
          trx.nextOccurrence.isBefore(now) &&
          guard++ < 366) {
        newTransactions.add(
          TransactionModel(
            title: trx.title,
            amount: trx.amount,
            type: trx.type,
            date: trx.nextOccurrence,
            category: trx.category,
            paymentMethod: trx.paymentMethod,
          ),
        );
        trx.updateNextOccurrence();
        if (trx.endDate != null && trx.nextOccurrence.isAfter(trx.endDate!)) {
          trx.isActive = false;
        }
      }
      dueKeys.add(key);
      if (trx.hasReminder && trx.isActive) {
        reminders.add(NotificationService.scheduleReminder(trx, key + 1000));
      }
    }

    if (newTransactions.isNotEmpty) {
      await hiveService.addAll(newTransactions);
    }
    for (final key in dueKeys) {
      await box.get(key)?.save();
    }
    await Future.wait(reminders);
  } catch (_) {
    // Background catch-up must never crash startup.
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => TransactionCubit(HiveService())..load(),
        ),
        BlocProvider(
          create: (context) => RecurringCubit(HiveService())..load(),
        ),
        BlocProvider(create: (context) => BudgetCubit(HiveService())..load()),
        BlocProvider(create: (context) => SavingCubit(HiveService())..load()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Money Tracker',
        locale: const Locale('id', 'ID'),
        supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366F1), // Modern Indigo
            primary: const Color(0xFF6366F1),
            secondary: const Color(0xFF818CF8),
            surface: Colors.white,
            onSurface: const Color(0xFF1E293B),
            surfaceContainerHighest: const Color(0xFFF8FAFC),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.plusJakartaSansTextTheme(
            Theme.of(context).textTheme,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
            actionsIconTheme: IconThemeData(color: Colors.white),
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            color: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF6366F1),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            prefixIconColor: const Color(0xFF6366F1),
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              shadowColor: const Color(0xFF6366F1).withOpacity(0.3),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
        ),
        home: const HomePage(),
      ),
    );
  }
}
