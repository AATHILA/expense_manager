import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart' as models;
import '../models/budget.dart';
import '../models/category.dart';

class StorageService {
  static Database? _database;
  static const String _databaseName = 'expense_manager.db';
  static const int _databaseVersion = 3;

  // Table names
  static const String transactionsTable = 'transactions';
  static const String budgetsTable = 'budgets';
  static const String settingsTable = 'settings';
  static const String categoriesTable = 'categories';
  static const String budgetAlertsTable = 'budget_alerts';

  // Initialize database
  static Future<void> init() async {
    if (_database != null) return;

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create database tables
  static Future<void> _onCreate(Database db, int version) async {
    // Create transactions table
    await db.execute('''
      CREATE TABLE $transactionsTable (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // Create budgets table
    await db.execute('''
      CREATE TABLE $budgetsTable (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        budget_limit REAL NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL
      )
    ''');

    // Create settings table
    await db.execute('''
      CREATE TABLE $settingsTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Create categories table
    await db.execute('''
      CREATE TABLE $categoriesTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        icon_code_point INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        is_expense INTEGER NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create budget alerts table
    await db.execute('''
      CREATE TABLE $budgetAlertsTable (
        category TEXT NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        skip_alerts INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (category, month, year)
      )
    ''');

    // Seed default categories
    await _seedDefaultCategories(db);
  }

  // Handle database upgrades
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add categories table
      await db.execute('''
        CREATE TABLE $categoriesTable (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          icon_code_point INTEGER NOT NULL,
          color_value INTEGER NOT NULL,
          is_expense INTEGER NOT NULL,
          is_default INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Seed default categories
      await _seedDefaultCategories(db);
    }

    if (oldVersion < 3) {
      // Add budget alerts table
      await db.execute('''
        CREATE TABLE $budgetAlertsTable (
          category TEXT NOT NULL,
          month INTEGER NOT NULL,
          year INTEGER NOT NULL,
          skip_alerts INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (category, month, year)
        )
      ''');
    }
  }

  // Seed default categories
  static Future<void> _seedDefaultCategories(Database db) async {
    const uuid = Uuid();

    // Add default expense categories
    for (var cat in DefaultCategories.expenseCategories) {
      await db.insert(categoriesTable, {
        'id': uuid.v4(),
        'name': cat['name'],
        'icon_code_point': cat['iconCodePoint'],
        'color_value': cat['colorValue'],
        'is_expense': 1,
        'is_default': 1,
      });
    }

    // Add default income categories
    for (var cat in DefaultCategories.incomeCategories) {
      await db.insert(categoriesTable, {
        'id': uuid.v4(),
        'name': cat['name'],
        'icon_code_point': cat['iconCodePoint'],
        'color_value': cat['colorValue'],
        'is_expense': 0,
        'is_default': 1,
      });
    }
  }

  // Get database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    await init();
    return _database!;
  }

  // Transaction operations
  static Future<void> addTransaction(models.Transaction transaction) async {
    final db = await database;
    await db.insert(
      transactionsTable,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateTransaction(models.Transaction transaction) async {
    final db = await database;
    await db.update(
      transactionsTable,
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  static Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
      transactionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static List<models.Transaction> getAllTransactions() {
    // This needs to be async, but we'll handle it in the BLoC
    throw UnimplementedError('Use getAllTransactionsAsync instead');
  }

  static Future<List<models.Transaction>> getAllTransactionsAsync() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(transactionsTable);
    return List.generate(maps.length, (i) {
      return models.Transaction.fromMap(maps[i]);
    });
  }

  static Future<models.Transaction?> getTransaction(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      transactionsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return models.Transaction.fromMap(maps.first);
  }

  // Budget operations
  static Future<void> addBudget(Budget budget) async {
    final db = await database;
    await db.insert(
      budgetsTable,
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateBudget(Budget budget) async {
    final db = await database;
    await db.update(
      budgetsTable,
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  static Future<void> deleteBudget(String id) async {
    final db = await database;
    await db.delete(
      budgetsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static List<Budget> getAllBudgets() {
    // This needs to be async, but we'll handle it in the BLoC
    throw UnimplementedError('Use getAllBudgetsAsync instead');
  }

  static Future<List<Budget>> getAllBudgetsAsync() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(budgetsTable);
    return List.generate(maps.length, (i) {
      return Budget.fromMap(maps[i]);
    });
  }

  static Future<Budget?> getBudget(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      budgetsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }

  // Settings operations
  static Future<void> setThemeMode(bool isDark) async {
    final db = await database;
    await db.insert(
      settingsTable,
      {'key': 'isDarkMode', 'value': isDark.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<bool> getThemeModeAsync() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      settingsTable,
      where: 'key = ?',
      whereArgs: ['isDarkMode'],
    );
    if (maps.isEmpty) return false;
    return maps.first['value'] == 'true';
  }

  static bool getThemeMode() {
    // This needs to be async, but we'll handle it in the BLoC
    throw UnimplementedError('Use getThemeModeAsync instead');
  }

  // Currency operations
  static Future<void> setCurrency(String currencyCode, String currencySymbol) async {
    final db = await database;
    await db.insert(
      settingsTable,
      {'key': 'currencyCode', 'value': currencyCode},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      settingsTable,
      {'key': 'currencySymbol', 'value': currencySymbol},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getCurrencyCode() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      settingsTable,
      where: 'key = ?',
      whereArgs: ['currencyCode'],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  static Future<String?> getCurrencySymbol() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      settingsTable,
      where: 'key = ?',
      whereArgs: ['currencySymbol'],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  static Future<bool> isCurrencySet() async {
    final currencyCode = await getCurrencyCode();
    return currencyCode != null;
  }

  // Category operations
  static Future<void> addCategory(ExpenseCategory category) async {
    final db = await database;
    await db.insert(
      categoriesTable,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateCategory(ExpenseCategory category) async {
    final db = await database;

    // Get the old category name before updating
    final List<Map<String, dynamic>> oldCategoryMaps = await db.query(
      categoriesTable,
      where: 'id = ?',
      whereArgs: [category.id],
    );

    if (oldCategoryMaps.isNotEmpty) {
      final oldCategoryName = oldCategoryMaps.first['name'] as String;

      // If the category name has changed, update all references
      if (oldCategoryName != category.name) {
        // Update all transactions with the old category name
        await db.update(
          transactionsTable,
          {'category': category.name},
          where: 'category = ?',
          whereArgs: [oldCategoryName],
        );

        // Update all budgets with the old category name
        await db.update(
          budgetsTable,
          {'category': category.name},
          where: 'category = ?',
          whereArgs: [oldCategoryName],
        );

        // Update all budget alerts with the old category name
        await db.update(
          budgetAlertsTable,
          {'category': category.name},
          where: 'category = ?',
          whereArgs: [oldCategoryName],
        );
      }
    }

    // Update the category itself
    await db.update(
      categoriesTable,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  static Future<void> deleteCategory(String id) async {
    final db = await database;
    await db.delete(
      categoriesTable,
      where: 'id = ? AND is_default = 0',
      whereArgs: [id],
    );
  }

  static Future<List<ExpenseCategory>> getAllCategoriesAsync() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(categoriesTable);
    return List.generate(maps.length, (i) {
      return ExpenseCategory.fromMap(maps[i]);
    });
  }

  static Future<List<ExpenseCategory>> getCategoriesByType(bool isExpense) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      categoriesTable,
      where: 'is_expense = ?',
      whereArgs: [isExpense ? 1 : 0],
    );
    return List.generate(maps.length, (i) {
      return ExpenseCategory.fromMap(maps[i]);
    });
  }

  static Future<ExpenseCategory?> getCategoryById(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      categoriesTable,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return ExpenseCategory.fromMap(maps.first);
  }

  static Future<ExpenseCategory?> getCategoryByName(String name, bool isExpense) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      categoriesTable,
      where: 'name = ? AND is_expense = ?',
      whereArgs: [name, isExpense ? 1 : 0],
    );
    if (maps.isEmpty) return null;
    return ExpenseCategory.fromMap(maps.first);
  }

  static Future<bool> isCategoryInUse(String categoryName) async {
    final db = await database;

    // Check if category is used in transactions
    final transactionCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM $transactionsTable WHERE category = ?',
        [categoryName],
      ),
    );

    // Check if category is used in budgets
    final budgetCount = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM $budgetsTable WHERE category = ?',
        [categoryName],
      ),
    );

    return (transactionCount ?? 0) > 0 || (budgetCount ?? 0) > 0;
  }

  // Budget Alert Preference operations
  static Future<void> setBudgetAlertPreference(
      String category,
      int month,
      int year,
      bool skipAlerts,
      ) async {
    final db = await database;
    await db.insert(
      budgetAlertsTable,
      {
        'category': category,
        'month': month,
        'year': year,
        'skip_alerts': skipAlerts ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<bool> shouldSkipBudgetAlert(
      String category,
      int month,
      int year,
      ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      budgetAlertsTable,
      where: 'category = ? AND month = ? AND year = ?',
      whereArgs: [category, month, year],
    );
    if (maps.isEmpty) return false;
    return maps.first['skip_alerts'] == 1;
  }

  static Future<void> clearBudgetAlertPreference(
      String category,
      int month,
      int year,
      ) async {
    final db = await database;
    await db.delete(
      budgetAlertsTable,
      where: 'category = ? AND month = ? AND year = ?',
      whereArgs: [category, month, year],
    );
  }

  // Generic settings operations
  static Future<void> setSettingValue(String key, String value) async {
    final db = await database;
    await db.insert(
      settingsTable,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> getSettingValue(String key) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      settingsTable,
      where: 'key = ?',
      whereArgs: [key],
    );
    if (maps.isEmpty) return null;
    return maps.first['value'] as String?;
  }

  static Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(settingsTable);
    final Map<String, String> settings = {};
    for (var map in maps) {
      settings[map['key'] as String] = map['value'] as String;
    }
    return settings;
  }

  // Close database connection
  static void closeDatabase() {
    _database = null;
  }
}

