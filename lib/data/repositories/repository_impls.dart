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
      String userMessage;
      switch (e.code) {
        case 'user-not-found':
          userMessage = 'No account found with this email address. Please check and try again.';
          break;
        case 'wrong-password':
          userMessage = 'Incorrect password. Please try again or use "Forgot Password".';
          break;
        case 'invalid-email':
          userMessage = 'The email address is not valid. Please enter a valid email.';
          break;
        case 'user-disabled':
          userMessage = 'This account has been disabled. Please contact support.';
          break;
        case 'too-many-requests':
          userMessage = 'Too many failed attempts. Please try again later.';
          break;
        case 'network-request-failed':
          userMessage = 'Network connection issue. Please check your internet and try again.';
          break;
        default:
          userMessage = 'Unable to sign in. Please check your credentials and try again.';
      }
      throw Exception(userMessage);
    } catch (e) {
      throw Exception('Something went wrong. Please try again later.');
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
      String userMessage;
      switch (e.code) {
        case 'email-already-in-use':
          userMessage = 'This email is already registered. Please use a different email or try logging in.';
          break;
        case 'invalid-email':
          userMessage = 'Please enter a valid email address.';
          break;
        case 'weak-password':
          userMessage = 'Password is too weak. Please use at least 6 characters with a mix of letters and numbers.';
          break;
        case 'operation-not-allowed':
          userMessage = 'Registration is currently unavailable. Please try again later.';
          break;
        case 'network-request-failed':
          userMessage = 'Network connection issue. Please check your internet and try again.';
          break;
        default:
          userMessage = 'Unable to create account. Please check your information and try again.';
      }
      throw Exception(userMessage);
    } catch (e) {
      throw Exception('Something went wrong. Please try again later.');
    }
  }

  @override
  Future<UserEntity> updateUser(UserEntity user) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) throw Exception('Please login to update your profile');
      
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
      throw Exception('Failed to update profile. Please check your connection and try again.');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Unable to logout. Please try again.');
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        if (doc.exists) {
          return UserEntity.fromMap({...doc.data()!, 'id': firebaseUser.uid});
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      String userMessage;
      switch (e.code) {
        case 'user-not-found':
          userMessage = 'No account found with this email address.';
          break;
        case 'invalid-email':
          userMessage = 'Please enter a valid email address.';
          break;
        case 'network-request-failed':
          userMessage = 'Network connection issue. Please check your internet and try again.';
          break;
        default:
          userMessage = 'Unable to send reset email. Please try again later.';
      }
      throw Exception(userMessage);
    } catch (e) {
      throw Exception('Something went wrong. Please try again later.');
    }
  }

  @override
  Future<bool> checkEmailExists(String email) async {
    return false; 
  }

  @override
  Future<void> updatePassword(String email, String newPassword) async {
    try {
      if (_firebaseAuth.currentUser != null) {
        await _firebaseAuth.currentUser!.updatePassword(newPassword);
      } else {
        throw Exception('Please login to update your password');
      }
    } on FirebaseAuthException catch (e) {
      String userMessage;
      switch (e.code) {
        case 'weak-password':
          userMessage = 'Password is too weak. Please use at least 6 characters with a mix of letters and numbers.';
          break;
        case 'requires-recent-login':
          userMessage = 'For security reasons, please login again before changing your password.';
          break;
        case 'network-request-failed':
          userMessage = 'Network connection issue. Please check your internet and try again.';
          break;
        default:
          userMessage = 'Unable to update password. Please try again later.';
      }
      throw Exception(userMessage);
    } catch (e) {
      throw Exception('Something went wrong. Please try again later.');
    }
  }
}

class FirebaseTransactionRepositoryImpl implements TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<TransactionEntity>> getTransactions({int? limit, int? offset, String? userId}) async {
    if (userId == null) return [];
    
    try {
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('date', descending: true);
      
      if (limit != null) query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => TransactionEntity.fromMap({...doc.data() as Map<String, dynamic>, 'id': doc.id})).toList();
    } catch (e) {
      throw Exception('Unable to load transactions. Please check your connection.');
    }
  }

  @override
  Future<String> addTransaction(TransactionEntity transaction) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(transaction.userId)
          .collection('transactions')
          .add(transaction.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Unable to save transaction. Please try again.');
    }
  }

  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {
    try {
      await _firestore
          .collection('users')
          .doc(transaction.userId)
          .collection('transactions')
          .doc(transaction.id)
          .update(transaction.toMap());
    } catch (e) {
      throw Exception('Unable to update transaction. Please try again.');
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Please login to delete transactions');
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Unable to delete transaction. Please try again.');
    }
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

    try {
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
    } catch (e) {
      throw Exception('Unable to filter transactions. Please try again.');
    }
  }
}

class FirebaseCategoryRepositoryImpl implements CategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<CategoryEntity>> getCategories() async {
    try {
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
    } catch (e) {
      throw Exception('Unable to load categories. Please check your connection.');
    }
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
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Please login to add categories');

      final docRef = await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .add(category.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Unable to add category. Please try again.');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('Please login to delete categories');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .doc(id)
          .delete();
    } catch (e) {
      throw Exception('Unable to delete category. Please try again.');
    }
  }
}