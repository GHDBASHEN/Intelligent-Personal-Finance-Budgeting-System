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
  ConsumerState<DashboardAnalyticsScreen> createState() =>
      _DashboardAnalyticsScreenState();
}

class _DashboardAnalyticsScreenState
    extends ConsumerState<DashboardAnalyticsScreen> {
  String selectedPeriod = 'Month';
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

    if (period == 'Day') {
      start = DateTime(now.year, now.month, now.day);
    } else if (period == 'Week') {
      start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
    } else if (period == 'Month') {
      start = DateTime(now.year, now.month, 1);
    } else if (period == 'Year') {
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
        data: (categories) =>
            _buildContent(filteredTransactions, categories, currencyNotifier),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildContent(
    List<TransactionEntity> transactions,
    List<CategoryEntity> categories,
    dynamic currencyNotifier,
  ) {
    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Group expenses by category
    final categoryTotals = <int, double>{};
    for (var tx in transactions.where(
      (t) => t.type == TransactionType.expense,
    )) {
      categoryTotals[tx.categoryId] =
          (categoryTotals[tx.categoryId] ?? 0) + tx.amount;
    }

    // Find highest category
    String highestCategoryName = "None";
    double highestAmount = 0;
    if (categoryTotals.isNotEmpty) {
      final sortedKeys = categoryTotals.keys.toList()
        ..sort((a, b) => categoryTotals[b]!.compareTo(categoryTotals[a]!));
      final topCatId = sortedKeys.first;
      final category = categories.firstWhere(
        (c) => c.id == topCatId,
        orElse: () =>
            CategoryEntity(name: "Unknown", icon: "", color: "0xFF808080"),
      );
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
          _buildSummarySection(
            income,
            expense,
            highestCategoryName,
            highestAmount,
            currencyNotifier,
          ),
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
        children: ['Day', 'Week', 'Month', 'Year', 'All Time'].map((period) {
          final isSelected = selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => _updateFilter(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  period,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummarySection(
    double income,
    double expense,
    String highestCategory,
    double highestAmount,
    dynamic currencyNotifier,
  ) {
    final balance = income - expense;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                "Total Income",
                income,
                const Color.fromARGB(255, 67, 128, 234),
                currencyNotifier,
                Icons.account_balance_wallet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                "Total Spending",
                expense,
                Colors.redAccent,
                currencyNotifier,
                Icons.shopping_cart,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                "Budget Balance",
                balance,
                balance >= 0 ? Colors.green : Colors.orangeAccent,
                currencyNotifier,
                Icons.account_balance,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                elevation: 4,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Colors.amber.withAlpha(20)],
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          const Text(
                            "Top Spending",
                            style: TextStyle(
                              color: Colors.amber,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        highestCategory,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 8,
                          color: Color.fromARGB(221, 57, 24, 24),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currencyNotifier.format(
                          currencyNotifier.convert(highestAmount),
                        ),
                        style: const TextStyle(
                          color: Color.fromARGB(255, 171, 69, 69),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
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

  Widget _summaryCard(
    String title,
    double amount,
    Color color,
    dynamic currencyNotifier,
    IconData icon,
  ) {
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
            colors: [Colors.white, color.withAlpha(12)],
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              child: Text(
                currencyNotifier.format(currencyNotifier.convert(amount)),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(
    Map<int, double> categoryTotals,
    List<CategoryEntity> categories,
  ) {
    if (categoryTotals.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text(
          "No expenses to chart",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final totalExpense = categoryTotals.values.fold(0.0, (a, b) => a + b);

    // Prepare legend data
    final legendItems = categoryTotals.entries.map((e) {
      final category = categories.firstWhere(
        (c) => c.id == e.key,
        orElse: () =>
            CategoryEntity(name: "Unknown", icon: "", color: "0xFF808080"),
      );
      final color = Color(
        int.parse(category.color.replaceFirst('0x', ''), radix: 16),
      );
      final percentage = (e.value / totalExpense * 100).toStringAsFixed(0);
      return {
        'name': category.name,
        'color': color,
        'amount': e.value,
        'percentage': percentage,
      };
    }).toList();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 3,
                    centerSpaceRadius: 40,
                    sections: categoryTotals.entries.map((e) {
                      final category = categories.firstWhere(
                        (c) => c.id == e.key,
                        orElse: () => CategoryEntity(
                          name: "Unknown",
                          icon: "",
                          color: "0xFF808080",
                        ),
                      );
                      final color = Color(
                        int.parse(
                          category.color.replaceFirst('0x', ''),
                          radix: 16,
                        ),
                      );

                      return PieChartSectionData(
                        value: e.value,
                        title: '',
                        color: color,
                        radius: 35,
                      );
                    }).toList(),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "TOTAL",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FittedBox(
                      child: Text(
                        totalExpense.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: legendItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: item['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "${item['name']} (${item['percentage']}%)",
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
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
        child: const Text(
          "No transaction trend available",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final Map<String, double> dailyExpenses = {};
    final Map<String, double> dailyIncome = {};

    // Grouping logic based on period
    String dateFormat;
    if (selectedPeriod == 'Day') {
      dateFormat = 'HH:00';
    } else if (selectedPeriod == 'Week') {
      dateFormat = 'EEE';
    } else if (selectedPeriod == 'Year' || selectedPeriod == 'All Time') {
      dateFormat = 'MMM';
    } else {
      dateFormat = 'MM/dd';
    }

    for (var tx in transactions) {
      final dateStr = DateFormat(dateFormat).format(tx.date);
      if (tx.type == TransactionType.expense) {
        dailyExpenses[dateStr] = (dailyExpenses[dateStr] ?? 0) + tx.amount;
      } else {
        dailyIncome[dateStr] = (dailyIncome[dateStr] ?? 0) + tx.amount;
      }
    }

    // Determine all unique date labels and sort them
    final allDates = {...dailyExpenses.keys, ...dailyIncome.keys}.toList();
    
    // Custom sort for labels to be chronological
    if (selectedPeriod == 'Week') {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      allDates.sort((a, b) => weekdays.indexOf(a).compareTo(weekdays.indexOf(b)));
    } else if (selectedPeriod == 'Year' || selectedPeriod == 'All Time') {
       final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
       allDates.sort((a, b) => months.indexOf(a).compareTo(months.indexOf(b)));
    } else {
      allDates.sort();
    }

    double maxVal = 0;
    List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < allDates.length; i++) {
      final label = allDates[i];
      final inc = dailyIncome[label] ?? 0;
      final exp = dailyExpenses[label] ?? 0;

      if (inc > maxVal) maxVal = inc;
      if (exp > maxVal) maxVal = exp;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: inc,
              color: Colors.blueAccent,
              width: 8,
              borderRadius: BorderRadius.circular(2),
            ),
            BarChartRodData(
              toY: exp,
              color: Colors.pinkAccent,
              width: 8,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      );
    }

    final maxY = (maxVal == 0 ? 100 : maxVal) * 1.2;
    // Calculate width based on number of bars (minimum width 300)
    final chartWidth = (allDates.length * 60.0).clamp(300.0, 2000.0);

    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
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
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                child: BarChart(
                  BarChartData(
                    maxY: maxY,
                    barGroups: barGroups,
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            if (value == 0 || value == maxY)
                              return const SizedBox();
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (val, meta) {
                            int index = val.toInt();
                            if (index >= 0 && index < allDates.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  allDates[index],
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) =>
                          FlLine(color: Colors.grey.withAlpha(30), strokeWidth: 1),
                    ),
                    borderData: FlBorderData(show: false),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.blueGrey.withAlpha(230),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            rod.toY.toStringAsFixed(0),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
