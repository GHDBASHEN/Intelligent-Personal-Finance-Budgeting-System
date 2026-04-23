import '../entities/user_entity.dart';
import '../entities/transaction_entity.dart';
import '../entities/category_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> login(String email, String password);
  Future<UserEntity> register(UserEntity user);
  Future<void> logout();
  Future<UserEntity?> getCurrentUser();
  Future<void> forgotPassword(String email);
  Future<bool> checkEmailExists(String email);
  Future<void> updatePassword(String email, String newPassword);
  Future<UserEntity> updateUser(UserEntity user);
}

abstract class TransactionRepository {
  Future<List<TransactionEntity>> getTransactions({int? limit, int? offset, String? userId});
  Future<String> addTransaction(TransactionEntity transaction);
  Future<void> updateTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(String id);
  Future<List<TransactionEntity>> filterTransactions({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    TransactionType? type,
  });
}

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getCategories();
  Future<String> addCategory(CategoryEntity category);
  Future<void> deleteCategory(String id);
}