import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/repository_impls.dart';
import '../../domain/repositories/repositories.dart';
import '../../data/sources/remote/currency_service.dart';
import '../../data/sources/remote/cloudinary_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepositoryImpl();
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return FirebaseTransactionRepositoryImpl();
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return FirebaseCategoryRepositoryImpl();
});

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService();
});

final cloudinaryServiceProvider = Provider<CloudinaryService>((ref) {
  return CloudinaryService();
});
