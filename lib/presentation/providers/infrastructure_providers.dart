// lib/presentation/providers/infrastructure_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/repository_impls.dart';
import '../../domain/repositories/repositories.dart';
import '../../data/sources/remote/currency_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepositoryImpl();
});

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService();
});