// lib/data/repositories/repository_impls.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/repositories.dart';
import '../sources/local/database_helper.dart';
import '../sources/local/password_hash_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  static const String _userKey = 'loggedInUserId';

  // Helper method to get database instance
  Future<Database> getDatabase() async {
    return await _dbHelper.database;
  }

  @override
  Future<UserEntity?> login(String email, String password) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    
    if (maps.isNotEmpty) {
      final userData = maps.first;
      final storedHash = userData['password'] as String;
      final salt = userData['password_salt'] as String ?? '';
      
      if (salt.isEmpty) {
        // Legacy user without salt - migrate them
        final newHash = PasswordHashService.createPasswordHash(password);
        await db.update(
          'users',
          {
            'password': newHash.hash,
            'password_salt': newHash.salt,
            'updated_at': DateTime.now().toIso8601String(),
          },
          where: 'id = ?',
          whereArgs: [userData['id']],
        );
        final user = UserEntity.fromMap(userData);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_userKey, user.id!);
        return user;
      }
      
      if (PasswordHashService.verifyPassword(password, salt, storedHash)) {
        final user = UserEntity.fromMap(userData);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_userKey, user.id!);
        return user;
      }
    }
    return null;
  }

  @override
  Future<UserEntity> register(UserEntity user) async {
    final db = await _dbHelper.database;
    
    final passwordHash = PasswordHashService.createPasswordHash(user.password);
    final now = DateTime.now().toIso8601String();
    
    final userMap = {
      'username': user.username,
      'email': user.email,
      'password': passwordHash.hash,
      'password_salt': passwordHash.salt,
      'profile_picture_path': user.profilePicturePath,
      'created_at': now,
      'updated_at': now,
      'default_currency': user.defaultCurrency,
    };
    
    final id = await db.insert('users', userMap);
    final newUser = UserEntity(
      id: id,
      username: user.username,
      email: user.email,
      password: '',
      profilePicturePath: user.profilePicturePath,
      createdAt: DateTime.parse(now),
      updatedAt: DateTime.parse(now),
      defaultCurrency: user.defaultCurrency,
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userKey, id);
    return newUser;
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_userKey);
    if (userId != null) {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
      if (maps.isNotEmpty) {
        return UserEntity.fromMap(maps.first);
      } else {
        await prefs.remove(_userKey);
      }
    }
    return null;
  }

  @override
  Future<void> forgotPassword(String email) async {
    throw Exception('Password reset is not supported for local authentication');
  }

  @override
  Future<bool> checkEmailExists(String email) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    return maps.isNotEmpty;
  }

  @override
  Future<void> updatePassword(String email, String newPassword) async {
    final db = await _dbHelper.database;
    final passwordHash = PasswordHashService.createPasswordHash(newPassword);
    await db.update(
      'users',
      {
        'password': passwordHash.hash,
        'password_salt': passwordHash.salt,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'email = ?',
      whereArgs: [email],
    );
  }
  
  Future<UserEntity> updateUserProfile(UserEntity updatedUser) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    
    final updateMap = {
      'username': updatedUser.username,
      'profile_picture_path': updatedUser.profilePicturePath,
      'updated_at': now,
    };
    
    await db.update(
      'users',
      updateMap,
      where: 'id = ?',
      whereArgs: [updatedUser.id],
    );
    
    return updatedUser.copyWith(updatedAt: DateTime.parse(now));
  }
  
  Future<void> updateUserPassword(int userId, String newPassword) async {
    final db = await _dbHelper.database;
    final passwordHash = PasswordHashService.createPasswordHash(newPassword);
    await db.update(
      'users',
      {
        'password': passwordHash.hash,
        'password_salt': passwordHash.salt,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Verify password directly
  Future<bool> verifyUserPassword(int userId, String password) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    
    if (maps.isEmpty) return false;
    
    final userData = maps.first;
    final storedHash = userData['password'] as String;
    final salt = userData['password_salt'] as String ?? '';
    
    if (salt.isEmpty) return false;
    
    return PasswordHashService.verifyPassword(password, salt, storedHash);
  }

  // Get user's default currency
  Future<String> getUserDefaultCurrency(int userId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (maps.isNotEmpty) {
      return maps.first['default_currency'] ?? 'USD';
    }
    return 'USD';
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