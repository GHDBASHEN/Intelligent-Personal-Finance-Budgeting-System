import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/currency_state_provider.dart';
import 'transaction_form_screen.dart';
import '../../widgets/custom_app_bar.dart';
import '../../providers/filter_provider.dart';
import 'widgets/filter_bottom_sheet.dart';

class TransactionsListScreen extends ConsumerStatefulWidget {
  const TransactionsListScreen({super.key});

  @override
  ConsumerState<TransactionsListScreen> createState() =>
      _TransactionsListScreenState();
}

class _TransactionsListScreenState
    extends ConsumerState<TransactionsListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(transactionProvider.notifier).fetchTransactions(),
    );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(transactionProvider.notifier).fetchTransactions();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transactionProvider);
    final filteredTransactions = ref.watch(filteredTransactionsProvider);
    final currencyNotifier = ref.watch(currencyStateProvider.notifier);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Transactions',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (ctx) => const FilterBottomSheet(),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(transactionProvider.notifier)
            .fetchTransactions(refresh: true),
        child: ListView.builder(
          controller: _scrollController,
          itemCount: filteredTransactions.length + (state.hasReachedMax ? 0 : 1),
          itemBuilder: (context, index) {
            if (index >= filteredTransactions.length) {
              if (state.transactions.isEmpty && !state.isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No transactions yet. Start by adding one!', style: TextStyle(fontSize: 16)),
                  ),
                );
              }
              if (filteredTransactions.isEmpty && state.transactions.isNotEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No transactions match the selected filters.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ),
                );
              }
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final tx = filteredTransactions[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: tx.type == TransactionType.income
                    ? Colors.greenAccent.withAlpha(51)
                    : Colors.orangeAccent.withAlpha(51),
                child: Icon(
                  tx.type == TransactionType.income ? Icons.arrow_downward : Icons.arrow_upward,
                  color: tx.type == TransactionType.income
                      ? Colors.green
                      : Colors.deepOrange,
                ),
              ),
              title: Text(
                tx.note.isEmpty ? 'Transaction' : tx.note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(DateFormat.yMMMd().format(tx.date)),
              trailing: Text(
                '${tx.type == TransactionType.income ? '+' : '-'} ${currencyNotifier.format(currencyNotifier.convert(tx.amount))}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: tx.type == TransactionType.income
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              onLongPress: () => ref
                  .read(transactionProvider.notifier)
                  .deleteTransaction(tx.id!),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const TransactionFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
