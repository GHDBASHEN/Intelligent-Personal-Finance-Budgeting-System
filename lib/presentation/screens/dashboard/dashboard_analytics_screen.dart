import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/currency_state_provider.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../widgets/custom_app_bar.dart';

class DashboardAnalyticsScreen extends ConsumerWidget {
  const DashboardAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionProvider);
    
    final now = DateTime.now();
    final todayTransactions = state.transactions.where((t) {
      return t.date.year == now.year &&
             t.date.month == now.month &&
             t.date.day == now.day;
    }).toList();

    todayTransactions.sort((a, b) => b.date.compareTo(a.date));

    final todayIncome = todayTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final todayExpense = todayTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: const CustomAppBar(title: "Today's Overview"),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryCards(todayIncome, todayExpense, ref.watch(currencyStateProvider), ref),
                  const SizedBox(height: 32),
                  const Text(
                    "Today's Trend",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildTodayLineChart(todayTransactions),
                  const SizedBox(height: 32),
                  const Text(
                    "Today's Activity",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (todayTransactions.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No transactions yet today.'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: todayTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = todayTransactions[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: tx.type == TransactionType.income 
                                ? Colors.green.withOpacity(0.2) 
                                : Colors.red.withOpacity(0.2),
                            child: Icon(
                              tx.type == TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward,
                              color: tx.type == TransactionType.income ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(tx.note),
                          subtitle: Text(DateFormat.jm().format(tx.date)),
                          trailing: Text(
                            ref.read(currencyStateProvider.notifier).format(
                                ref.read(currencyStateProvider.notifier).convert(tx.amount)
                            ),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: tx.type == TransactionType.income ? Colors.green : Colors.red,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/dashboard/past-details');
                },
                icon: const Icon(Icons.history),
                label: const Text('View past data with details'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(double income, double expense, CurrencyState cState, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard("Today's Balance", income - expense, Colors.blue, ref),
        ),
        const SizedBox(width: 8),
        Expanded(child: _summaryCard("Today's Expenses", expense, Colors.red, ref)),
      ],
    );
  }

  Widget _summaryCard(String title, double amount, Color color, WidgetRef ref) {
    final currencyNotifier = ref.read(currencyStateProvider.notifier);
    final converted = currencyNotifier.convert(amount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              currencyNotifier.format(converted),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayLineChart(List<TransactionEntity> transactions) {
    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    expenses.sort((a, b) => a.date.compareTo(b.date));

    final incomes = transactions.where((t) => t.type == TransactionType.income).toList();
    incomes.sort((a, b) => a.date.compareTo(b.date));

    List<FlSpot> expenseSpots = [];
    double cumulativeExpense = 0;
    
    if (expenses.isEmpty) {
      expenseSpots = [const FlSpot(0, 0), const FlSpot(24, 0)];
    } else {
      for (var tx in expenses) {
        cumulativeExpense += tx.amount;
        expenseSpots.add(FlSpot(tx.date.hour.toDouble() + (tx.date.minute / 60.0), cumulativeExpense));
      }
      if (expenseSpots.isNotEmpty && expenseSpots.first.x > 0) {
        expenseSpots.insert(0, const FlSpot(0, 0));
      }
    }

    List<FlSpot> incomeSpots = [];
    double cumulativeIncome = 0;

    if (incomes.isEmpty) {
      incomeSpots = [const FlSpot(0, 0), const FlSpot(24, 0)];
    } else {
      for (var tx in incomes) {
        cumulativeIncome += tx.amount;
        incomeSpots.add(FlSpot(tx.date.hour.toDouble() + (tx.date.minute / 60.0), cumulativeIncome));
      }
      if (incomeSpots.isNotEmpty && incomeSpots.first.x > 0) {
        incomeSpots.insert(0, const FlSpot(0, 0));
      }
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  if (value % 6 == 0 && value >= 0 && value <= 24) {
                    return Text('${value.toInt()}h', style: const TextStyle(fontSize: 10));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 24,
          minY: 0,
          lineBarsData: [
            LineChartBarData(
              spots: expenseSpots,
              isCurved: true,
              color: Colors.red,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.red.withOpacity(0.15),
              ),
            ),
            LineChartBarData(
              spots: incomeSpots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
