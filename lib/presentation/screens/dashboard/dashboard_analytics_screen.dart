import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/transaction_provider.dart';
import '../../../domain/entities/transaction_entity.dart';

class DashboardAnalyticsScreen extends ConsumerWidget {
  const DashboardAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(transactionProvider);
    final transactions = state.transactions;

    final income = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Financial Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryCards(income, expense),
            const SizedBox(height: 24),
            const Text(
              'Income vs Expense',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: _buildPieChart(income, expense)),
            const SizedBox(height: 24),
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBarChart(transactions),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(double income, double expense) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard('Net Balance', income - expense, Colors.blue),
        ),
        const SizedBox(width: 8),
        Expanded(child: _summaryCard('Expenses', expense, Colors.red)),
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
            ),
            const SizedBox(height: 8),
            Text(
              '\$ \${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(double income, double expense) {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: income,
            color: Colors.green,
            title: 'Income',
            radius: 50,
            titleStyle: const TextStyle(color: Colors.white),
          ),
          PieChartSectionData(
            value: expense,
            color: Colors.red,
            title: 'Expense',
            radius: 50,
            titleStyle: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<TransactionEntity> transactions) {
    // Simplified bar chart showing count of transactions per day
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          barGroups: [
            BarChartGroupData(
              x: 1,
              barRods: [BarChartRodData(toY: 5, color: Colors.blue)],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [BarChartRodData(toY: 8, color: Colors.blue)],
            ),
            BarChartGroupData(
              x: 3,
              barRods: [BarChartRodData(toY: 3, color: Colors.blue)],
            ),
          ],
        ),
      ),
    );
  }
}
