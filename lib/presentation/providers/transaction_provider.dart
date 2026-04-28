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
    final authState = ref.watch(authProvider);
    
    if (authState.user != null) {
        Future.microtask(() => fetchTransactions(refresh: true));
    }
    
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
      if (user == null) throw Exception('Please login to view transactions');

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
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (!errorMessage.startsWith('Please') && !errorMessage.startsWith('Unable') && !errorMessage.startsWith('Network')) {
        errorMessage = 'Unable to load transactions. Please pull down to refresh.';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<void> addTransaction(TransactionEntity transaction) async {
    try {
      await ref.read(transactionRepositoryProvider).addTransaction(transaction);
      fetchTransactions(refresh: true);
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(error: errorMessage);
    }
  }

  Future<void> deleteTransaction(String id) async {
    try {
      await ref.read(transactionRepositoryProvider).deleteTransaction(id);
      state = state.copyWith(
        transactions: state.transactions.where((t) => t.id != id).toList(),
      );
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(error: errorMessage);
    }
  }

  Future<void> applyFilters({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    TransactionType? type,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = ref.read(authProvider).user;
      if (user == null) throw Exception('Please login to filter transactions');
      
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
      );
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }
}

final transactionProvider =
    NotifierProvider<TransactionNotifier, TransactionState>(
      TransactionNotifier.new,
    );