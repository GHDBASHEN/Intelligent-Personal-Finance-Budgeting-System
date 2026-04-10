import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/category_provider.dart';
import '../../providers/filter_provider.dart';
import '../../providers/currency_state_provider.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../../domain/entities/category_entity.dart';
import '../../widgets/custom_app_bar.dart';

class DashboardAnalyticsScreen extends ConsumerStatefulWidget {
  const DashboardAnalyticsScreen({super.key});

  @override
  ConsumerState<DashboardAnalyticsScreen> createState() => _DashboardAnalyticsScreenState();
}

class _DashboardAnalyticsScreenState extends ConsumerState<DashboardAnalyticsScreen> {
  String selectedPeriod = 'This Month';
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      // Delay initialization to avoid provider modification during build
      Future.microtask(() => _updateFilter(selectedPeriod));
      _initialized = true;
    }
  }

  void _updateFilter(String period) {
    setState(() {
      selectedPeriod = period;
    });
    
    final now = DateTime.now();
    DateTime? start;
    DateTime? end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (period == 'This Week') {
      start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    } else if (period == 'This Month') {
      start = DateTime(now.year, now.month, 1);
    } else if (period == 'This Year') {
      start = DateTime(now.year, 1, 1);
    } else {
      start = null; // All Time
      end = null;
    }
    
    ref.read(filterProvider.notifier).setDateRange(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final filteredTransactions = ref.watch(filteredTransactionsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final currencyNotifier = ref.read(currencyStateProvider.notifier);

    return Scaffold(
      appBar: const CustomAppBar(title: "Analytics Dashboard"),
      body: categoriesAsync.when(
        data: (categories) => _buildContent(filteredTransactions, categories, currencyNotifier),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildContent(List<TransactionEntity> transactions, List<CategoryEntity> categories, dynamic currencyNotifier) {
    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Group expenses by category
    final categoryTotals = <int, double>{};
    for (var tx in transactions.where((t) => t.type == TransactionType.expense)) {
      categoryTotals[tx.categoryId] = (categoryTotals[tx.categoryId] ?? 0) + tx.amount;
    }

    // Find highest category
    String highestCategoryName = "None";
    double highestAmount = 0;
    if (categoryTotals.isNotEmpty) {
      final sortedKeys = categoryTotals.keys.toList()
        ..sort((a, b) => categoryTotals[b]!.compareTo(categoryTotals[a]!));
      final topCatId = sortedKeys.first;
      final category = categories.firstWhere((c) => c.id == topCatId, 
         orElse: () => CategoryEntity(name: "Unknown", icon: "", color: "0xFF808080"));
      highestCategoryName = category.name;
      highestAmount = categoryTotals[topCatId]!;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(),
          const SizedBox(height: 24),
          _buildSummarySection(income, expense, highestCategoryName, highestAmount, currencyNotifier),
          const SizedBox(height: 32),
          const Text(
            "Expense Breakdown",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildPieChart(categoryTotals, categories),
          const SizedBox(height: 32),
          const Text(
            "Expense vs Income Trend",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildTrendBarChart(transactions),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      height: 45,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: ['This Week', 'This Month', 'This Year', 'All Time'].map((period) {
          final isSelected = selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => _updateFilter(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  period,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummarySection(double income, double expense, String highestCategory, double highestAmount, dynamic currencyNotifier) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _summaryCard("Income", income, Colors.green, currencyNotifier, Icons.arrow_downward)),
            const SizedBox(width: 12),
            Expanded(child: _summaryCard("Expenses", expense, Colors.red, currencyNotifier, Icons.arrow_upward)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _summaryCard("Savings", income - expense, Colors.blue, currencyNotifier, Icons.account_balance_wallet)),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          const Text("Top Cat", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        highestCategory, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currencyNotifier.format(currencyNotifier.convert(highestAmount)),
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(String title, double amount, Color color, dynamic currencyNotifier, IconData icon) {
    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              color.withAlpha(12),
            ],
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              child: Text(
                currencyNotifier.format(currencyNotifier.convert(amount)),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<int, double> categoryTotals, List<CategoryEntity> categories) {
    if (categoryTotals.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text("No expenses to chart", style: TextStyle(color: Colors.grey)),
      );
    }

    final totalExpense = categoryTotals.values.fold(0.0, (a, b) => a + b);

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 50,
              sections: categoryTotals.entries.map((e) {
                final category = categories.firstWhere((c) => c.id == e.key,
                    orElse: () => CategoryEntity(name: "Unknown", icon: "", color: "0xFF808080"));
                final color = Color(int.parse(category.color.replaceFirst('0x', ''), radix: 16));
                
                return PieChartSectionData(
                  value: e.value,
                  title: '${(e.value / totalExpense * 100).toStringAsFixed(0)}%',
                  color: color,
                  radius: 40,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                );
              }).toList(),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("TOTAL", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
              FittedBox(
                child: Text(
                  totalExpense.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBarChart(List<TransactionEntity> transactions) {
     if (transactions.isEmpty) {
       return Container(
         height: 100,
         alignment: Alignment.center,
         child: const Text("No transaction trend available", style: TextStyle(color: Colors.grey)),
       );
     }
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendItem("Income", Colors.blueAccent),
              const SizedBox(width: 20),
              _legendItem("Expenses", Colors.pinkAccent),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (transactions.isEmpty ? 100 : transactions.map((t) => t.amount).reduce((a, b) => a > b ? a : b)) * 1.2,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => Colors.blueGrey.withAlpha(230),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                       return BarTooltipItem(
                         rod.toY.toStringAsFixed(0),
                         const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                       );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                         // Find the date for this index if possible
                         return Padding(
                           padding: const EdgeInsets.only(top: 10.0),
                           child: Text('${val.toInt() + 1}', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                         );
                      }
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: _generateBarGroups(transactions),
              ),
              duration: const Duration(milliseconds: 750),
              curve: Curves.easeInOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
      ],
    );
  }

  List<BarChartGroupData> _generateBarGroups(List<TransactionEntity> transactions) {
     final Map<String, double> dailyExpenses = {};
     final Map<String, double> dailyIncome = {};
     
     for (var tx in transactions) {
       final dateStr = DateFormat('MM/dd').format(tx.date);
       if (tx.type == TransactionType.expense) {
         dailyExpenses[dateStr] = (dailyExpenses[dateStr] ?? 0) + tx.amount;
       } else {
         dailyIncome[dateStr] = (dailyIncome[dateStr] ?? 0) + tx.amount;
       }
     }

     final allDates = {...dailyExpenses.keys, ...dailyIncome.keys}.toList()..sort();
     final displayDates = allDates.length > 6 ? allDates.sublist(allDates.length - 6) : allDates;

     List<BarChartGroupData> groups = [];
     int x = 0;
     for (var date in displayDates) {
       groups.add(
         BarChartGroupData(
           x: x++,
           barsSpace: 4,
           barRods: [
             BarChartRodData(
               toY: dailyIncome[date] ?? 0,
               gradient: const LinearGradient(
                 colors: [Colors.blue, Colors.lightBlueAccent],
                 begin: Alignment.bottomCenter,
                 end: Alignment.topCenter,
               ),
               width: 8,
               borderRadius: BorderRadius.circular(4),
             ),
             BarChartRodData(
               toY: dailyExpenses[date] ?? 0,
               gradient: const LinearGradient(
                 colors: [Colors.pink, Colors.pinkAccent],
                 begin: Alignment.bottomCenter,
                 end: Alignment.topCenter,
               ),
               width: 8,
               borderRadius: BorderRadius.circular(4),
             ),
           ],
         ),
       );
     }
     
     return groups;
  }
}
