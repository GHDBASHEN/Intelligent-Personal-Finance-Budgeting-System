import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction_entity.dart';
import 'transaction_provider.dart';

class TransactionFilterCriteria {
  final String query;
  final TransactionType? type;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final int? year;
  final int? month;

  TransactionFilterCriteria({
    this.query = '',
    this.type,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.year,
    this.month,
  });

  TransactionFilterCriteria copyWith({
    String? query,
    TransactionType? type,
    bool clearType = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    double? minAmount,
    bool clearMinAmount = false,
    double? maxAmount,
    bool clearMaxAmount = false,
    int? year,
    bool clearYear = false,
    int? month,
    bool clearMonth = false,
  }) {
    return TransactionFilterCriteria(
      query: query ?? this.query,
      type: clearType ? null : (type ?? this.type),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      year: clearYear ? null : (year ?? this.year),
      month: clearMonth ? null : (month ?? this.month),
    );
  }
}

class TransactionFilterNotifier extends Notifier<TransactionFilterCriteria> {
  @override
  TransactionFilterCriteria build() {
    return TransactionFilterCriteria();
  }

  void updateQuery(String q) {
    state = state.copyWith(query: q);
  }

  void setType(TransactionType? t) {
    state = state.copyWith(type: t, clearType: t == null);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      startDate: start,
      clearStartDate: start == null,
      endDate: end,
      clearEndDate: end == null,
    );
  }

  void setAmountRange(double? min, double? max) {
    state = state.copyWith(
      minAmount: min,
      clearMinAmount: min == null,
      maxAmount: max,
      clearMaxAmount: max == null,
    );
  }

  void setYear(int? year) {
    state = state.copyWith(year: year, clearYear: year == null);
  }

  void setMonth(int? month) {
    state = state.copyWith(month: month, clearMonth: month == null);
  }

  void clearFilters() {
    state = TransactionFilterCriteria();
  }
}

final filterProvider = NotifierProvider<TransactionFilterNotifier, TransactionFilterCriteria>(
  TransactionFilterNotifier.new,
);

final analyticsFilterProvider = NotifierProvider<TransactionFilterNotifier, TransactionFilterCriteria>(
  TransactionFilterNotifier.new,
);

List<TransactionEntity> _applyFilterLogic(List<TransactionEntity> transactions, TransactionFilterCriteria filter) {
  return transactions.where((tx) {
    if (filter.query.isNotEmpty && !tx.note.toLowerCase().contains(filter.query.toLowerCase())) {
      return false;
    }
    if (filter.type != null && tx.type != filter.type) {
      return false;
    }
    if (filter.startDate != null && tx.date.isBefore(filter.startDate!)) {
      return false;
    }
    if (filter.endDate != null && tx.date.isAfter(filter.endDate!.add(const Duration(days: 1)))) {
      return false;
    }
    if (filter.minAmount != null && tx.amount < filter.minAmount!) {
      return false;
    }
    if (filter.maxAmount != null && tx.amount > filter.maxAmount!) {
      return false;
    }
    if (filter.year != null && tx.date.year != filter.year) {
      return false;
    }
    if (filter.month != null && tx.date.month != filter.month) {
      return false;
    }
    return true;
  }).toList();
}

final filteredTransactionsProvider = Provider<List<TransactionEntity>>((ref) {
  final transactions = ref.watch(transactionProvider).transactions;
  final filter = ref.watch(filterProvider);
  return _applyFilterLogic(transactions, filter);
});

final filteredAnalyticsTransactionsProvider = Provider<List<TransactionEntity>>((ref) {
  final transactions = ref.watch(transactionProvider).transactions;
  final filter = ref.watch(analyticsFilterProvider);
  return _applyFilterLogic(transactions, filter);
});
