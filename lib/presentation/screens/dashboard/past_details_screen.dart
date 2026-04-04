import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/transaction_provider.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../widgets/custom_app_bar.dart';

class PastDetailsScreen extends ConsumerWidget {
  const PastDetailsScreen({super.key});

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
      appBar: const CustomAppBar(title: 'Past Analytics Details'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryCards(income, expense),
            const SizedBox(height: 24),
            const Text(
              'All-Time Income vs Expense',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: _buildPieChart(income, expense)),
            const SizedBox(height: 24),
            const Text(
              'Historical Activity',
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
          child: _summaryCard('Total Balance', income - expense, Colors.blue),
        ),
        const SizedBox(width: 8),
        Expanded(child: _summaryCard('Total Expenses', expense, Colors.red)),
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
              '\$${amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(double income, double expense) {
    if (income == 0 && expense == 0) {
      return const Center(child: Text('No data available', style: TextStyle(color: Colors.grey)));
    }
    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(enabled: true),
        borderData: FlBorderData(show: false),
        sectionsSpace: 4,
        centerSpaceRadius: 50,
        sections: [
          PieChartSectionData(
            value: income,
            color: Colors.teal.shade300,
            title: 'Income',
            radius: 50,
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            badgeWidget: _buildBadge(Icons.arrow_downward, Colors.teal),
            badgePositionPercentageOffset: .98,
          ),
          PieChartSectionData(
            value: expense,
            color: Colors.orange.shade400,
            title: 'Expense',
            radius: 50,
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            badgeWidget: _buildBadge(Icons.arrow_upward, Colors.orange),
            badgePositionPercentageOffset: .98,
          ),
        ],
      ),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOutCubic,
    );
  }

  Widget _buildBadge(IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(6),
      child: Icon(icon, color: color, size: 16),
    );
  }

  Widget _buildBarChart(List<TransactionEntity> transactions) {
    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withAlpha(40),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const labels = ['Nov', 'Dec', 'Jan', 'Feb', 'Mar'];
                  if (value.toInt() >= 0 && value.toInt() < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        labels[value.toInt()],
                        style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          barGroups: [
            _buildModernBarGroup(0, 15, Colors.amber.shade400),
            _buildModernBarGroup(1, 25, Colors.orange.shade400),
            _buildModernBarGroup(2, 10, Colors.teal.shade300),
            _buildModernBarGroup(3, 30, Colors.redAccent.shade200),
            _buildModernBarGroup(4, 20, Colors.orange.shade400),
          ],
        ),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  BarChartGroupData _buildModernBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 22,
          color: color,
          borderRadius: BorderRadius.circular(6),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 35,
            color: Colors.grey.withAlpha(20),
          ),
        ),
      ],
    );
  }
}
