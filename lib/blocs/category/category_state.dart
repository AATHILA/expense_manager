import '../../models/category.dart';

abstract class CategoryState {}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<ExpenseCategory> categories;
  final bool? filterIsExpense;

  CategoryLoaded(this.categories, {this.filterIsExpense});

  List<ExpenseCategory> get expenseCategories =>
      categories.where((c) => c.isExpense).toList();

  List<ExpenseCategory> get incomeCategories =>
      categories.where((c) => !c.isExpense).toList();

  List<ExpenseCategory> get filteredCategories {
    if (filterIsExpense == null) return categories;
    return categories.where((c) => c.isExpense == filterIsExpense).toList();
  }

  List<String> get expenseCategoryNames =>
      expenseCategories.map((c) => c.name).toList();

  List<String> get incomeCategoryNames =>
      incomeCategories.map((c) => c.name).toList();

  ExpenseCategory? getCategoryByName(String name, bool isExpense) {
    try {
      return categories.firstWhere(
            (c) => c.name == name && c.isExpense == isExpense,
      );
    } catch (e) {
      return null;
    }
  }
}

class CategoryError extends CategoryState {
  final String message;

  CategoryError(this.message);
}

