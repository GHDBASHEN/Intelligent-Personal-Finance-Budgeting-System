import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../../domain/entities/transaction_entity.dart';

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
      appBar: AppBar(title: const Text("Today's Dashboard")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSummaryCards(todayIncome, todayExpense),
            const SizedBox(height: 32),
            const Text(
              "Today's Expense Trend",
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
                      '\$${tx.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tx.type == TransactionType.income ? Colors.green : Colors.red,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/dashboard/past-details');
                },
                icon: const Icon(Icons.history),
                label: const Text('View past data with details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double income, double expense) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard("Today's Balance", income - expense, Colors.blue),
        ),
        const SizedBox(width: 8),
        Expanded(child: _summaryCard("Today's Expenses", expense, Colors.red)),
      ],
    );
  }

  Widget _summaryCard(String title, double amount, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayLineChart(List<TransactionEntity> transactions) {
    final expenses = transactions.where((t) => t.type == TransactionType.expense).toList();
    // Sort chronologically for line chart
    expenses.sort((a, b) => a.date.compareTo(b.date));

    List<FlSpot> spots = [];
    double cumulative = 0;
    
    if (expenses.isEmpty) {
      spots = [const FlSpot(0, 0), const FlSpot(24, 0)];
    } else {
      for (var tx in expenses) {
        cumulative += tx.amount;
        spots.add(FlSpot(tx.date.hour.toDouble() + (tx.date.minute / 60.0), cumulative));
      }
      if (spots.isNotEmpty && spots.first.x > 0) {
        spots.insert(0, const FlSpot(0, 0));
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
              spots: spots,
              isCurved: true,
              color: Colors.redAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.redAccent.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
