import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction_entity.dart';
import 'infrastructure_providers.dart';
import 'auth_provider.dart';

class TransactionState {
  final List<TransactionEntity> transactions;
  final bool isLoading;
  final String? error;
  final bool hasReachedMax;

  TransactionState({
    this.transactions = const [],
    this.isLoading = false,
    this.error,
    this.hasReachedMax = false,
  });

  TransactionState copyWith({
    List<TransactionEntity>? transactions,
    bool? isLoading,
    String? error,
    bool? hasReachedMax,
  }) {
    return TransactionState(
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

class TransactionNotifier extends Notifier<TransactionState> {
  final int _pageSize = 20;
  int _currentOffset = 0;

  @override
  TransactionState build() {
    // Initial fetch
    Future.microtask(() => fetchTransactions());
    return TransactionState();
  }

  Future<void> fetchTransactions({bool refresh = false}) async {
    if (state.isLoading || (state.hasReachedMax && !refresh)) return;

    if (refresh) {
      _currentOffset = 0;
      state = state.copyWith(transactions: [], hasReachedMax: false);
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = ref.read(authProvider).user;
      if (user == null) throw Exception('User not authenticated');

      final newTransactions = await ref
          .read(transactionRepositoryProvider)
          .getTransactions(
            limit: _pageSize,
            offset: _currentOffset,
            userId: user.id,
          );

      if (newTransactions.isEmpty) {
        state = state.copyWith(isLoading: false, hasReachedMax: true);
      } else {
        _currentOffset += newTransactions.length;
        state = state.copyWith(
          transactions: [...state.transactions, ...newTransactions],
          isLoading: false,
          hasReachedMax: newTransactions.length < _pageSize,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addTransaction(TransactionEntity transaction) async {
    try {
      await ref.read(transactionRepositoryProvider).addTransaction(transaction);
      fetchTransactions(refresh: true); // Refresh list
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteTransaction(int id) async {
    try {
      await ref.read(transactionRepositoryProvider).deleteTransaction(id);
      state = state.copyWith(
        transactions: state.transactions.where((t) => t.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Method for complex filtering
  Future<void> applyFilters({
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    TransactionType? type,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = ref.read(authProvider).user;
      final filtered = await ref
          .read(transactionRepositoryProvider)
          .filterTransactions(
            userId: user?.id,
            startDate: startDate,
            endDate: endDate,
            categoryId: categoryId,
            type: type,
          );
      state = state.copyWith(
        transactions: filtered,
        isLoading: false,
        hasReachedMax: true,
      ); // Disable pagination for filtered results in this simple mock
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final transactionProvider =
    NotifierProvider<TransactionNotifier, TransactionState>(
      TransactionNotifier.new,
    );
