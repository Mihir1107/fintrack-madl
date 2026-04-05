import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/budget_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._();

  Database? _db;

  Future<Database> get database async => _db ??= await _init();

  Future<Database> _init() async {
    final path = p.join(await getDatabasesPath(), 'fintrack.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id INTEGER,
        date TEXT NOT NULL,
        notes TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        type TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        month TEXT NOT NULL,
        UNIQUE(category_id, month)
      )
    ''');
    await _seed(db);
  }

  Future<void> _seed(Database db) async {
    // Using Material color hex values directly to avoid Color.value deprecation
    final cats = [
      ('Food & Dining', Icons.restaurant.codePoint, 0xFFFF9800, 'expense'),
      ('Transport', Icons.directions_car.codePoint, 0xFF2196F3, 'expense'),
      ('Shopping', Icons.shopping_bag.codePoint, 0xFF9C27B0, 'expense'),
      ('Bills & Utilities', Icons.receipt_long.codePoint, 0xFFF44336, 'expense'),
      ('Entertainment', Icons.movie.codePoint, 0xFFE91E63, 'expense'),
      ('Healthcare', Icons.local_hospital.codePoint, 0xFF009688, 'expense'),
      ('Education', Icons.school.codePoint, 0xFF3F51B5, 'expense'),
      ('Groceries', Icons.local_grocery_store.codePoint, 0xFF8BC34A, 'expense'),
      ('Salary', Icons.work.codePoint, 0xFF4CAF50, 'income'),
      ('Freelance', Icons.laptop.codePoint, 0xFF00BCD4, 'income'),
      ('Investment', Icons.trending_up.codePoint, 0xFFFFC107, 'income'),
      ('Gift', Icons.card_giftcard.codePoint, 0xFFFF5722, 'income'),
      ('Other', Icons.more_horiz.codePoint, 0xFF9E9E9E, 'both'),
    ];
    for (final (name, icon, color, type) in cats) {
      await db.insert('categories', {
        'name': name,
        'icon_code': icon,
        'color_value': color,
        'type': type,
      });
    }
  }

  // ── Transactions ─────────────────────────────────────────────────────────

  Future<int> insertTransaction(TransactionModel t) async {
    return (await database).insert('transactions', t.toMap());
  }

  Future<List<TransactionModel>> getTransactions({String? type}) async {
    final rows = await (await database).query(
      'transactions',
      where: type != null ? 'type = ?' : null,
      whereArgs: type != null ? [type] : null,
      orderBy: 'date DESC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<List<TransactionModel>> getRecentTransactions(int limit) async {
    final rows = await (await database).query(
      'transactions',
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<int> updateTransaction(TransactionModel t) async {
    return (await database).update(
      'transactions',
      t.toMap(),
      where: 'id = ?',
      whereArgs: [t.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    return (await database).delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ── Categories ───────────────────────────────────────────────────────────

  Future<int> insertCategory(CategoryModel c) async {
    return (await database).insert('categories', c.toMap());
  }

  Future<List<CategoryModel>> getCategories({String? type}) async {
    final db = await database;
    final rows = type != null
        ? await db.query('categories',
            where: "type = ? OR type = 'both'", whereArgs: [type])
        : await db.query('categories');
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<int> updateCategory(CategoryModel c) async {
    return (await database).update(
      'categories',
      c.toMap(),
      where: 'id = ?',
      whereArgs: [c.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    return (await database).delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ── Budgets ──────────────────────────────────────────────────────────────

  Future<void> upsertBudget(BudgetModel b) async {
    await (await database).insert(
      'budgets',
      b.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<BudgetModel>> getBudgets(String month) async {
    final rows = await (await database).query(
      'budgets',
      where: 'month = ?',
      whereArgs: [month],
    );
    return rows.map(BudgetModel.fromMap).toList();
  }

  Future<int> deleteBudget(int id) async {
    return (await database).delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  // ── Summary queries ──────────────────────────────────────────────────────

  Future<Map<String, double>> getTotalSummary() async {
    final db = await database;
    final inc = (await db.rawQuery(
            "SELECT COALESCE(SUM(amount),0) AS v FROM transactions WHERE type='income'"))
        .first['v'] as num;
    final exp = (await db.rawQuery(
            "SELECT COALESCE(SUM(amount),0) AS v FROM transactions WHERE type='expense'"))
        .first['v'] as num;
    return {
      'income': inc.toDouble(),
      'expense': exp.toDouble(),
      'balance': (inc - exp).toDouble(),
    };
  }

  Future<Map<String, double>> getMonthlySummary(String month) async {
    final db = await database;
    final inc = (await db.rawQuery(
            "SELECT COALESCE(SUM(amount),0) AS v FROM transactions WHERE type='income' AND date LIKE ?",
            ['$month%']))
        .first['v'] as num;
    final exp = (await db.rawQuery(
            "SELECT COALESCE(SUM(amount),0) AS v FROM transactions WHERE type='expense' AND date LIKE ?",
            ['$month%']))
        .first['v'] as num;
    return {
      'income': inc.toDouble(),
      'expense': exp.toDouble(),
      'balance': (inc - exp).toDouble(),
    };
  }

  Future<Map<int, double>> getCategoryExpenses(String month) async {
    final rows = await (await database).rawQuery(
      "SELECT category_id, SUM(amount) AS total FROM transactions "
      "WHERE type='expense' AND date LIKE ? AND category_id IS NOT NULL "
      "GROUP BY category_id",
      ['$month%'],
    );
    return {
      for (final r in rows)
        r['category_id'] as int: (r['total'] as num).toDouble()
    };
  }
}
