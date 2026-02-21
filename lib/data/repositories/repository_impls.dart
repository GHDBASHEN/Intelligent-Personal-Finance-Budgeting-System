import '../../domain/entities/user_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/repositories.dart';
import '../sources/local/database_helper.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<UserEntity?> login(String email, String password) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (maps.isNotEmpty) {
      return UserEntity.fromMap(maps.first);
    }
    return null;
  }

  @override
  Future<UserEntity> register(UserEntity user) async {
    final db = await _dbHelper.database;
    final id = await db.insert('users', user.toMap());
    return UserEntity(
      id: id,
      username: user.username,
      email: user.email,
      password: user.password,
    );
  }

  @override
  Future<void> logout() async {
    // Session management would go here
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    // Mocking current user for simplicity in this exercise
    return null;
  }
}

class TransactionRepositoryImpl implements TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<List<TransactionEntity>> getTransactions({int? limit, int? offset, int? userId}) async {
    final db = await _dbHelper.database;
    String? where;
    List<dynamic>? whereArgs;
    if (userId != null) {
      where = 'user_id = ?';
      whereArgs = [userId];
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: where,
      whereArgs: whereArgs,
      limit: limit,
      offset: offset,
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => TransactionEntity.fromMap(maps[i]));
  }

  @override
  Future<int> addTransaction(TransactionEntity transaction) async {
    final db = await _dbHelper.database;
    return await db.insert('transactions', transaction.toMap());
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    final db = await _dbHelper.database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  @override
  Future<void> deleteTransaction(int id) async {
    final db = await _dbHelper.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<TransactionEntity>> filterTransactions({
    int? userId,
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
    TransactionType? type,
  }) async {
    final db = await _dbHelper.database;
    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (userId != null) {
      whereClauses.add('user_id = ?');
      whereArgs.add(userId);
    }
    if (startDate != null) {
      whereClauses.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }
    if (endDate != null) {
      whereClauses.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }
    if (categoryId != null) {
      whereClauses.add('category_id = ?');
      whereArgs.add(categoryId);
    }
    if (type != null) {
      whereClauses.add('type = ?');
      whereArgs.add(type.name);
    }

    String? where = whereClauses.isEmpty ? null : whereClauses.join(' AND ');

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => TransactionEntity.fromMap(maps[i]));
  }
}

class CategoryRepositoryImpl implements CategoryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => CategoryEntity.fromMap(maps[i]));
  }

  @override
  Future<int> addCategory(CategoryEntity category) async {
    final db = await _dbHelper.database;
    return await db.insert('categories', category.toMap());
  }

  @override
  Future<void> deleteCategory(int id) async {
    final db = await _dbHelper.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
