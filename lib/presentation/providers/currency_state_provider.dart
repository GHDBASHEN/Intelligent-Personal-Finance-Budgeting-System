// lib/presentation/providers/currency_state_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'infrastructure_providers.dart';
import '../../data/repositories/repository_impls.dart';

class CurrencyState {
  final String baseCurrency;
  final String targetCurrency;
  final Map<String, double> rates;
  final bool isLoading;
  final String? error;

  CurrencyState({
    this.baseCurrency = 'USD',
    this.targetCurrency = 'USD',
    this.rates = const {'USD': 1.0},
    this.isLoading = false,
    this.error,
  });

  CurrencyState copyWith({
    String? baseCurrency,
    String? targetCurrency,
    Map<String, double>? rates,
    bool? isLoading,
    String? error,
  }) {
    return CurrencyState(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      targetCurrency: targetCurrency ?? this.targetCurrency,
      rates: rates ?? this.rates,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class CurrencyNotifier extends Notifier<CurrencyState> {
  @override
  CurrencyState build() {
    Future.microtask(() => fetchRates());
    return CurrencyState();
  }

  Future<void> fetchRates() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final currencyService = ref.read(currencyServiceProvider);
      final data = await currencyService.getExchangeRates(state.baseCurrency);
      
      final dynamic ratesData = data['rates'];
      Map<String, double> parsedRates = {};
      
      if (ratesData != null) {
        (ratesData as Map<String, dynamic>).forEach((key, value) {
          parsedRates[key] = (value as num).toDouble();
        });
      } else {
        parsedRates = {'USD': 1.0};
      }

      state = state.copyWith(
        rates: parsedRates,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setTargetCurrency(String currency) {
    state = state.copyWith(targetCurrency: currency);
  }

  // Load user's default currency from database
  Future<void> loadUserDefaultCurrency(int userId) async {
    final authRepo = AuthRepositoryImpl();
    final defaultCurrency = await authRepo.getUserDefaultCurrency(userId);
    state = state.copyWith(targetCurrency: defaultCurrency, baseCurrency: defaultCurrency);
  }

  double convert(double amount) {
    if (state.baseCurrency == state.targetCurrency) return amount;
    
    final rate = state.rates[state.targetCurrency];
    if (rate == null) return amount;
    
    return amount * rate;
  }

  double convertToBase(double amount, String fromCurrency) {
    if (state.baseCurrency == fromCurrency) return amount;
    
    final rate = state.rates[fromCurrency];
    if (rate == null || rate == 0) return amount;
    
    return amount / rate;
  }

  String format(double amount) {
    final f = NumberFormat.simpleCurrency(name: state.targetCurrency);
    return f.format(amount);
  }
}

final currencyStateProvider =
    NotifierProvider<CurrencyNotifier, CurrencyState>(CurrencyNotifier.new);