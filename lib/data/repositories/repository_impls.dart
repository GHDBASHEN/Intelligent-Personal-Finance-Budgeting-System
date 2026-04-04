import 'package:firebase_auth/firebase_auth.dart';
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

class FirebaseAuthRepositoryImpl implements AuthRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Future<UserEntity?> login(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      if (maps.isNotEmpty) {
        return UserEntity.fromMap(maps.first);
      } else {
        final newUser = UserEntity(
          username: _firebaseAuth.currentUser?.displayName ?? email.split('@')[0],
          email: email,
          password: 'firebase_auth', // Dummy password for local sync
        );
        final id = await db.insert('users', newUser.toMap());
        return UserEntity(
          id: id,
          username: newUser.username,
          email: newUser.email,
          password: newUser.password,
        );
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Authentication failed');
    } catch (e) {
      throw Exception('An error occurred during login');
    }
  }

  @override
  Future<UserEntity> register(UserEntity user) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password,
      );
      
      await userCredential.user?.updateDisplayName(user.username);
      
      final db = await _dbHelper.database;
      final id = await db.insert('users', user.toMap());
      return UserEntity(
        id: id,
        username: user.username,
        email: user.email,
        password: user.password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Registration failed');
    } catch (e) {
      throw Exception('An error occurred during registration');
    }
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    // Wait for the first emitted state to guarantee Firebase has restored the native session
    final firebaseUser = await _firebaseAuth.authStateChanges().first;
    if (firebaseUser != null && firebaseUser.email != null) {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [firebaseUser.email],
      );
      if (maps.isNotEmpty) {
        return UserEntity.fromMap(maps.first);
      } else {
        // Hydrate local database if session exists in Firebase but not locally
        final newUser = UserEntity(
          username: firebaseUser.displayName ?? firebaseUser.email!.split('@')[0],
          email: firebaseUser.email!,
          password: 'firebase_auth',
        );
        final id = await db.insert('users', newUser.toMap());
        return UserEntity(
          id: id,
          username: newUser.username,
          email: newUser.email,
          password: newUser.password,
        );
      }
    }
    return null;
  }
}
