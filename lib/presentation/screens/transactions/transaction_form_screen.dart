import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/custom_app_bar.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final TransactionEntity? transaction;
  const TransactionFormScreen({super.key, this.transaction});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late double _amount;
  late String _note;
  late DateTime _selectedDate;
  late TransactionType _type;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _amount = widget.transaction?.amount ?? 0;
    _note = widget.transaction?.note ?? '';
    _selectedDate = widget.transaction?.date ?? DateTime.now();
    _type = widget.transaction?.type ?? TransactionType.expense;
    _selectedCategoryId = widget.transaction?.categoryId;
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final user = ref.read(authProvider).user;
      
      int? categoryId = _selectedCategoryId;
      if (_type == TransactionType.income) {
        final categories = ref.read(categoriesProvider).value;
        if (categories != null && categories.isNotEmpty) {
          final incomeCategory = categories.firstWhere(
            (c) => c.name.toLowerCase() == 'salary',
            orElse: () => categories.first,
          );
          categoryId = incomeCategory.id;
        } else {
          categoryId = 1; // default index in local DB
        }
      }

      if (user == null || categoryId == null) return;

      final newTransaction = TransactionEntity(
        id: widget.transaction?.id,
        userId: user.id!,
        categoryId: categoryId,
        amount: _amount,
        note: _note,
        date: _selectedDate,
        type: _type,
      );

      ref.read(transactionProvider.notifier).addTransaction(newTransaction);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.transaction == null
            ? 'Add Transaction'
            : 'Edit Transaction',
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SegmentedButton<TransactionType>(
                segments: const [
                  ButtonSegment(
                    value: TransactionType.income,
                    label: Text('Income'),
                  ),
                  ButtonSegment(
                    value: TransactionType.expense,
                    label: Text('Expense'),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (Set<TransactionType> selection) {
                  setState(() => _type = selection.first);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _amount == 0 ? '' : _amount.toString(),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (val) =>
                    (val == null || double.tryParse(val) == null)
                    ? 'Enter valid amount'
                    : null,
                onSaved: (val) => _amount = double.parse(val!),
              ),
              const SizedBox(height: 16),
              if (_type == TransactionType.expense) ...[
                categoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<int>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: categories
                        .map(
                          (cat) => DropdownMenuItem(
                            value: cat.id,
                            child: Text(cat.name),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                    validator: (val) => val == null ? 'Select category' : null,
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (e, s) => Text('Error loading categories: \$e'),
                ),
                const SizedBox(height: 16),
              ],
              ListTile(
                title: Text(
                  'Date: ${DateFormat.yMMMd().format(_selectedDate)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _note,
                decoration: InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  prefixIcon: const Icon(Icons.note),
                ),
                onSaved: (val) => _note = val ?? '',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveForm,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Save Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
