import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:money_tracker/blocs/transaction_cubit.dart';
import 'package:money_tracker/models/transaction_model.dart';
import 'package:money_tracker/services/hive_service.dart';
import 'package:money_tracker/views/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TransactionModelAdapter());

  await Hive.openBox<TransactionModel>('transactions');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TransactionCubit(HiveService())..load(),
      child: MaterialApp(
        title: 'Money Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6750A4),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}
