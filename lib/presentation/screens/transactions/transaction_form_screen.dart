import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/currency_state_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../../data/sources/remote/open_food_facts_service.dart';
import 'scanner_screen.dart';

class TransactionFormScreen extends ConsumerStatefulWidget {
  final TransactionEntity? transaction;
  const TransactionFormScreen({super.key, this.transaction});

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  late double _amount;
  late DateTime _selectedDate;
  late TransactionType _type;
  int? _selectedCategoryId;
  String? _selectedEntryCurrency;

  @override
  void initState() {
    super.initState();
    _amount = widget.transaction?.amount ?? 0;
    _noteController.text = widget.transaction?.note ?? '';
    _selectedDate = widget.transaction?.date ?? DateTime.now();
    _type = widget.transaction?.type ?? TransactionType.expense;
    _selectedCategoryId = widget.transaction?.categoryId;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
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

      if (user == null || categoryId == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: User or category is missing. Please restart the app or select a category.')),
        );
        return;
      }

      double finalAmount = _amount;
      if (_selectedEntryCurrency != null) {
        finalAmount = ref.read(currencyStateProvider.notifier).convertToBase(_amount, _selectedEntryCurrency!);
      } else {
        // If they didn't manually pick an override, treat their input as if it's currently the targetCurrency.
        // E.g., if their target feature shows EUR everywhere, assume they entered the amount in EUR.
        final targetCurrency = ref.read(currencyStateProvider).targetCurrency;
        finalAmount = ref.read(currencyStateProvider.notifier).convertToBase(_amount, targetCurrency);
      }

      final newTransaction = TransactionEntity(
        id: widget.transaction?.id,
        userId: user.id!,
        categoryId: categoryId,
        amount: finalAmount,
        note: _noteController.text,
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
              Consumer(
                builder: (context, ref, child) {
                  final currencyState = ref.watch(currencyStateProvider);
                  final availableCurrencies = currencyState.rates.keys.toList()..sort();
                  final currentCurrency = _selectedEntryCurrency ?? currencyState.targetCurrency;

                  return TextFormField(
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
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: availableCurrencies.contains(currentCurrency) ? currentCurrency : null,
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                            items: availableCurrencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) {
                              setState(() => _selectedEntryCurrency = val);
                            },
                          ),
                        ),
                      ),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (val) =>
                        (val == null || double.tryParse(val) == null)
                        ? 'Enter valid amount'
                        : null,
                    onSaved: (val) => _amount = double.parse(val!),
                  );
                },
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
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: 'Note / Product',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  prefixIcon: const Icon(Icons.note),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.blueAccent),
                    tooltip: 'Scan Product Barcode',
                    onPressed: () async {
                      final barcode = await Navigator.of(context).push<String>(
                        MaterialPageRoute(builder: (_) => const ScannerScreen()),
                      );
                      if (barcode != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fetching product details...')));
                        final productName = await OpenFoodFactsService().getProductName(barcode);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          if (productName != null) {
                            setState(() {
                              _noteController.text = productName;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product not found in Open Food Facts')));
                          }
                        }
                      }
                    },
                  ),
                ),
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
