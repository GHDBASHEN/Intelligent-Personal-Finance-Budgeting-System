import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../providers/filter_provider.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();
  int? _selectedYear;
  int? _selectedMonth;

  @override
  void initState() {
    super.initState();
    final currentFilters = ref.read(filterProvider);
    _queryController.text = currentFilters.query;
    _minAmountController.text = currentFilters.minAmount?.toString() ?? '';
    _maxAmountController.text = currentFilters.maxAmount?.toString() ?? '';
    _selectedYear = currentFilters.year;
    _selectedMonth = currentFilters.month;
  }

  @override
  void dispose() {
    _queryController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final notifier = ref.read(filterProvider.notifier);
    notifier.updateQuery(_queryController.text);
    notifier.setAmountRange(
      double.tryParse(_minAmountController.text),
      double.tryParse(_maxAmountController.text),
    );
    notifier.setYear(_selectedYear);
    notifier.setMonth(_selectedMonth);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final currentFilters = ref.watch(filterProvider);
    final notifier = ref.read(filterProvider.notifier);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filters', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    notifier.clearFilters();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Clear All', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                labelText: 'Search by Note',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.withAlpha(20),
                border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(16))),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: currentFilters.type == null,
                  onSelected: (val) => notifier.setType(null),
                  selectedColor: Colors.amber.shade200,
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Income'),
                  selected: currentFilters.type == TransactionType.income,
                  onSelected: (val) => notifier.setType(TransactionType.income),
                  selectedColor: Colors.green.shade200,
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Expense'),
                  selected: currentFilters.type == TransactionType.expense,
                  onSelected: (val) => notifier.setType(TransactionType.expense),
                  selectedColor: Colors.orange.shade200,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Amount Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Min (\$)', 
                      filled: true,
                      fillColor: Colors.grey.withAlpha(20),
                      border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12)))
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _maxAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Max (\$)', 
                      filled: true,
                      fillColor: Colors.grey.withAlpha(20),
                      border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12)))
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Date Filter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedYear,
                    decoration: InputDecoration(
                      labelText: 'Year',
                      filled: true,
                      fillColor: Colors.grey.withAlpha(20),
                      border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      ...List.generate(11, (index) => 2020 + index).map((year) => DropdownMenuItem(value: year, child: Text(year.toString()))),
                    ],
                    onChanged: (val) => setState(() => _selectedYear = val),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedMonth,
                    decoration: InputDecoration(
                      labelText: 'Month',
                      filled: true,
                      fillColor: Colors.grey.withAlpha(20),
                      border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      ...List.generate(12, (index) => index + 1).map((month) => DropdownMenuItem(
                            value: month,
                            child: Text([
                              'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                              'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                            ][month - 1]),
                          )),
                    ],
                    onChanged: (val) => setState(() => _selectedMonth = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                elevation: 4,
              ),
              child: const Text('Apply Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
