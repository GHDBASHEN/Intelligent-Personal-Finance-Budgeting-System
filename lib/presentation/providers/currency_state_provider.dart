import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'infrastructure_providers.dart';

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
    // Initial fetch
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

  double convert(double amount) {
    if (state.baseCurrency == state.targetCurrency) return amount;
    
    final rate = state.rates[state.targetCurrency];
    if (rate == null) return amount; // Fallback if rate not found
    
    return amount * rate;
  }
}

final currencyStateProvider =
    NotifierProvider<CurrencyNotifier, CurrencyState>(CurrencyNotifier.new);
