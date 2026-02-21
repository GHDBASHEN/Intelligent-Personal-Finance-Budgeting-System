import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'finance_system.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        is_default INTEGER DEFAULT 0
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE NO ACTION
      )
    ''');

    // Seed default categories
    await _seedCategories(db);
  }

  Future _seedCategories(Database db) async {
    List<Map<String, dynamic>> defaultCategories = [
      {'name': 'Food', 'icon': 'restaurant', 'color': '0xFFFF5722', 'is_default': 1},
      {'name': 'Transport', 'icon': 'directions_car', 'color': '0xFF2196F3', 'is_default': 1},
      {'name': 'Housing', 'icon': 'home', 'color': '0xFF4CAF50', 'is_default': 1},
      {'name': 'Entertainment', 'icon': 'movie', 'color': '0xFF9C27B0', 'is_default': 1},
      {'name': 'Shopping', 'icon': 'shopping_bag', 'color': '0xFFE91E63', 'is_default': 1},
      {'name': 'Salary', 'icon': 'payments', 'color': '0xFF4CAF50', 'is_default': 1},
      {'name': 'Interest', 'icon': 'account_balance', 'color': '0xFF009688', 'is_default': 1},
    ];

    for (var cat in defaultCategories) {
      await db.insert('categories', cat);
    }
  }
}
