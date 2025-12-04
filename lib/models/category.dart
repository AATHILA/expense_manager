import 'package:flutter/material.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final int iconCodePoint;
  final int colorValue;
  final bool isExpense;
  final bool isDefault;

  ExpenseCategory({
    required this.id,
    required this.name,
    required this.iconCodePoint,
    required this.colorValue,
    required this.isExpense,
    this.isDefault = false,
  });

  // Helper getters for icon and color
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_code_point': iconCodePoint,
      'color_value': colorValue,
      'is_expense': isExpense ? 1 : 0,
      'is_default': isDefault ? 1 : 0,
    };
  }

  // Create from Map
  factory ExpenseCategory.fromMap(Map<String, dynamic> map) {
    return ExpenseCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      iconCodePoint: map['icon_code_point'] as int,
      colorValue: map['color_value'] as int,
      isExpense: (map['is_expense'] as int) == 1,
      isDefault: (map['is_default'] as int) == 1,
    );
  }

  ExpenseCategory copyWith({
    String? id,
    String? name,
    int? iconCodePoint,
    int? colorValue,
    bool? isExpense,
    bool? isDefault,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
      isExpense: isExpense ?? this.isExpense,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class DefaultCategories {
  // Default expense categories
  static List<Map<String, dynamic>> get expenseCategories => [
    {
      'name': 'Food',
      'iconCodePoint': Icons.restaurant.codePoint,
      'colorValue': Colors.orange.toARGB32(),
    },
    {
      'name': 'Travel',
      'iconCodePoint': Icons.flight.codePoint,
      'colorValue': Colors.blue.toARGB32(),
    },
    {
      'name': 'Bills',
      'iconCodePoint': Icons.receipt_long.codePoint,
      'colorValue': Colors.red.toARGB32(),
    },
    {
      'name': 'Shopping',
      'iconCodePoint': Icons.shopping_bag.codePoint,
      'colorValue': Colors.purple.toARGB32(),
    },
    {
      'name': 'Entertainment',
      'iconCodePoint': Icons.movie.codePoint,
      'colorValue': Colors.pink.toARGB32(),
    },
    {
      'name': 'Health',
      'iconCodePoint': Icons.local_hospital.codePoint,
      'colorValue': Colors.green.toARGB32(),
    },
    {
      'name': 'Education',
      'iconCodePoint': Icons.school.codePoint,
      'colorValue': Colors.indigo.toARGB32(),
    },
    {
      'name': 'Other',
      'iconCodePoint': Icons.more_horiz.codePoint,
      'colorValue': Colors.grey.toARGB32(),
    },
  ];

  // Default income categories
  static List<Map<String, dynamic>> get incomeCategories => [
    {
      'name': 'Salary',
      'iconCodePoint': Icons.account_balance_wallet.codePoint,
      'colorValue': Colors.green.toARGB32(),
    },
    {
      'name': 'Business',
      'iconCodePoint': Icons.business.codePoint,
      'colorValue': Colors.teal.toARGB32(),
    },
    {
      'name': 'Investment',
      'iconCodePoint': Icons.trending_up.codePoint,
      'colorValue': Colors.lightGreen.toARGB32(),
    },
    {
      'name': 'Other',
      'iconCodePoint': Icons.more_horiz.codePoint,
      'colorValue': Colors.grey.toARGB32(),
    },
  ];
}

