import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../providers/transaction_provider.dart';
import 'transaction_form_screen.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter dialog
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
          itemCount: state.transactions.length + (state.hasReachedMax ? 0 : 1),
          itemBuilder: (context, index) {
            if (index >= state.transactions.length) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            final tx = state.transactions[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: tx.type == TransactionType.income
                    ? Colors.green.shade100
                    : Colors.red.shade100,
                child: Icon(
                  tx.type == TransactionType.income ? Icons.add : Icons.remove,
                  color: tx.type == TransactionType.income
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              title: Text(tx.note.isEmpty ? 'Transaction' : tx.note),
              subtitle: Text(DateFormat.yMMMd().format(tx.date)),
              trailing: Text(
                '${tx.type == TransactionType.income ? '+' : '-'} ${tx.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
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
