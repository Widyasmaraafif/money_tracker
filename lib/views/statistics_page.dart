import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../utils/categories.dart';

class StatisticsPage extends StatelessWidget {
  final List<TransactionModel> transactions;

  const StatisticsPage({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    final expenseTransactions = transactions.where((t) => t.type == 'expense').toList();
    final totalExpense = expenseTransactions.fold(0.0, (sum, item) => sum + item.amount);

    final Map<String, double> categoryData = {};
    for (var t in expenseTransactions) {
      categoryData[t.category] = (categoryData[t.category] ?? 0) + t.amount;
    }

    final sortedCategories = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Statistik Pengeluaran'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.primary.withOpacity(0.8),
              colorScheme.secondary.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: kToolbarHeight + 40),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (expenseTransactions.isEmpty)
                      SizedBox(
                        height: 300,
                        child: Center(
                          child: Text(
                            'Belum ada data pengeluaran',
                            style: textTheme.bodyLarge?.copyWith(color: Colors.grey),
                          ),
                        ),
                      )
                    else ...[
                      SizedBox(
                        height: 250,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 50,
                            sections: sortedCategories.map((entry) {
                              final category = TransactionCategory.getByName(entry.key);
                              final percentage = (entry.value / totalExpense) * 100;
                              return PieChartSectionData(
                                color: category.color,
                                value: entry.value,
                                title: '${percentage.toStringAsFixed(0)}%',
                                radius: 60,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sortedCategories.length,
                        separatorBuilder: (context, index) => const Divider(height: 24),
                        itemBuilder: (context, index) {
                          final entry = sortedCategories[index];
                          final category = TransactionCategory.getByName(entry.key);
                          final percentage = (entry.value / totalExpense) * 100;

                          return Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: category.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(category.icon, color: category.color, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.name,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${percentage.toStringAsFixed(1)}% dari total',
                                      style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp ',
                                  decimalDigits: 0,
                                ).format(entry.value),
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
