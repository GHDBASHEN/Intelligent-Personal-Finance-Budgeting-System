// lib/data/sources/local/database_helper.dart
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
      version: 3,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        password_salt TEXT NOT NULL,
        profile_picture_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        default_currency TEXT DEFAULT 'USD'
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color TEXT NOT NULL,
        is_default INTEGER DEFAULT 0
      )
    ''');

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

    await _seedCategories(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN default_currency TEXT DEFAULT "USD"');
      } catch (e) {}
    }
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE users ADD COLUMN password_salt TEXT DEFAULT ""');
      } catch (e) {}
      try {
        await db.execute('ALTER TABLE users ADD COLUMN profile_picture_path TEXT');
      } catch (e) {}
      try {
        await db.execute('ALTER TABLE users ADD COLUMN created_at TEXT');
      } catch (e) {}
      try {
        await db.execute('ALTER TABLE users ADD COLUMN updated_at TEXT');
      } catch (e) {}
      
      final now = DateTime.now().toIso8601String();
      await db.execute('UPDATE users SET created_at = "$now", updated_at = "$now" WHERE created_at IS NULL');
    }
  }

  Future _seedCategories(Database db) async {
    final existing = await db.query('categories');
    if (existing.isEmpty) {
      List<Map<String, dynamic>> defaultCategories = [
        {'name': 'Food', 'icon': 'restaurant', 'color': '0xFFFF5722', 'is_default': 1},
        {'name': 'Transport', 'icon': 'directions_car', 'color': '0xFF2196F3', 'is_default': 1},
        {'name': 'Housing', 'icon': 'home', 'color': '0xFF4CAF50', 'is_default': 1},
        {'name': 'Entertainment', 'icon': 'movie', 'color': '0xFF9C27B0', 'is_default': 1},
        {'name': 'Shopping', 'icon': 'shopping_bag', 'color': '0xFFE91E63', 'is_default': 1},
        {'name': 'Salary', 'icon': 'attach_money', 'color': '0xFF4CAF50', 'is_default': 1},
      ];
      for (var cat in defaultCategories) {
        await db.insert('categories', cat);
      }
    }
  }
}