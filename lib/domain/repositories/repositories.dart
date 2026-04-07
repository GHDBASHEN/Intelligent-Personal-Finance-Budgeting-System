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
}

abstract class TransactionRepository {
  Future<List<TransactionEntity>> getTransactions({int? limit, int? offset, int? userId});
  Future<int> addTransaction(TransactionEntity transaction);
  Future<void> updateTransaction(TransactionEntity transaction);
  Future<void> deleteTransaction(int id);
  Future<List<TransactionEntity>> filterTransactions({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    TransactionType? type,
  });
}

abstract class CategoryRepository {
  Future<List<CategoryEntity>> getCategories();
  Future<int> addCategory(CategoryEntity category);
  Future<void> deleteCategory(int id);
}
