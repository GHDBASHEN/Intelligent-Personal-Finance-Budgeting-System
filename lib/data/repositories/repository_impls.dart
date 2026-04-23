import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/repositories.dart';
import '../sources/local/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseAuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<UserEntity?> login(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists) {
          return UserEntity.fromMap({...doc.data()!, 'id': firebaseUser.uid});
        } else {
          final user = UserEntity(
            id: firebaseUser.uid,
            username: firebaseUser.displayName ?? email.split('@')[0],
            email: email,
            password: '',
            preferredCurrency: 'USD',
            createdAt: DateTime.now(),
          );
          await _firestore.collection('users').doc(firebaseUser.uid).set(user.toMap());
          return user;
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Authentication failed');
    }
  }

  @override
  Future<UserEntity> register(UserEntity user) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: user.email,
        password: user.password,
      );
      
      final firebaseUser = userCredential.user;
      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(user.username);
        final newUser = UserEntity(
          id: firebaseUser.uid,
          username: user.username,
          email: user.email,
          password: '',
          preferredCurrency: null,
          phoneNumber: user.phoneNumber,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toMap());
        
        final categoryRepo = FirebaseCategoryRepositoryImpl();
        await categoryRepo.seedDefaultCategories(firebaseUser.uid);
        
        return newUser;
      }
      throw Exception('User creation failed');
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Registration failed');
    }
  }

  @override
  Future<UserEntity> updateUser(UserEntity user) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) throw Exception('User not logged in');
      
      if (user.username != firebaseUser.displayName) {
        await firebaseUser.updateDisplayName(user.username);
      }
      
      final Map<String, dynamic> userData = {};
      if (user.username != firebaseUser.displayName) {
        userData['username'] = user.username;
      }
      if (user.profileImageUrl != null) {
        userData['profileImageUrl'] = user.profileImageUrl;
      }
      if (user.preferredCurrency != null) {
        userData['preferredCurrency'] = user.preferredCurrency;
      }
      if (user.phoneNumber != null) {
        userData['phoneNumber'] = user.phoneNumber;
      }
      
      if (userData.isNotEmpty) {
        await _firestore.collection('users').doc(firebaseUser.uid).update(userData);
      }
      
      final updatedDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      return UserEntity.fromMap({...updatedDoc.data()!, 'id': firebaseUser.uid});
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        return UserEntity.fromMap({...doc.data()!, 'id': firebaseUser.uid});
      }
    }
    return null;
  }

  @override
  Future<void> forgotPassword(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<bool> checkEmailExists(String email) async {
    return false; 
  }

  @override
  Future<void> updatePassword(String email, String newPassword) async {
    if (_firebaseAuth.currentUser != null) {
      await _firebaseAuth.currentUser!.updatePassword(newPassword);
    }
  }
}

class FirebaseTransactionRepositoryImpl implements TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<TransactionEntity>> getTransactions({int? limit, int? offset, String? userId}) async {
    if (userId == null) return [];
    
    Query query = _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true);
    
    if (limit != null) query = query.limit(limit);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => TransactionEntity.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id})).toList();
  }

  @override
  Future<String> addTransaction(TransactionEntity transaction) async {
    final docRef = await _firestore
        .collection('users')
        .doc(transaction.userId)
        .collection('transactions')
        .add(transaction.toMap());
    return docRef.id;
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    await _firestore
        .collection('users')
        .doc(transaction.userId)
        .collection('transactions')
        .doc(transaction.id)
        .update(transaction.toMap());
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(id)
        .delete();
  }

  @override
  Future<List<TransactionEntity>> filterTransactions({
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    TransactionType? type,
  }) async {
    if (userId == null) return [];

    Query query = _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions');

    if (startDate != null) {
      query = query.where('date', isGreaterThanOrEqualTo: startDate.toIso8601String());
    }
    if (endDate != null) {
      query = query.where('date', isLessThanOrEqualTo: endDate.toIso8601String());
    }
    if (categoryId != null) {
      query = query.where('category_id', isEqualTo: categoryId);
    }
    if (type != null) {
      query = query.where('type', isEqualTo: type.name);
    }

    query = query.orderBy('date', descending: true);

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => TransactionEntity.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id})).toList();
  }
}

class FirebaseCategoryRepositoryImpl implements CategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<CategoryEntity>> getCategories() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return [];

    var snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .get();

    if (snapshot.docs.isEmpty) {
      await seedDefaultCategories(userId);
      snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .get();
    }

    return snapshot.docs.map((doc) => CategoryEntity.fromMap({...doc.data(), 'id': doc.id})).toList();
  }

  Future<void> seedDefaultCategories(String userId) async {
    final batch = _firestore.batch();
    final categories = [
      {'name': 'Food', 'icon': 'restaurant', 'color': '0xFFFF5722', 'is_default': 1},
      {'name': 'Transport', 'icon': 'directions_car', 'color': '0xFF2196F3', 'is_default': 1},
      {'name': 'Housing', 'icon': 'home', 'color': '0xFF4CAF50', 'is_default': 1},
      {'name': 'Entertainment', 'icon': 'movie', 'color': '0xFF9C27B0', 'is_default': 1},
      {'name': 'Shopping', 'icon': 'shopping_bag', 'color': '0xFFE91E63', 'is_default': 1},
      {'name': 'Salary', 'icon': 'payments', 'color': '0xFF2196F3', 'is_default': 1},
      {'name': 'Other', 'icon': 'more_horiz', 'color': '0xFF9E9E9E', 'is_default': 1},
    ];

    for (var cat in categories) {
      final docRef = _firestore.collection('users').doc(userId).collection('categories').doc();
      batch.set(docRef, cat);
    }
    await batch.commit();
  }

  @override
  Future<String> addCategory(CategoryEntity category) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    final docRef = await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .add(category.toMap());
    return docRef.id;
  }

  @override
  Future<void> deleteCategory(String id) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('categories')
        .doc(id)
        .delete();
  }
}