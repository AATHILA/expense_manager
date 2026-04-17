import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/category/category_bloc.dart';
import '../blocs/category/category_state.dart';
import '../models/category.dart';

class CategoryHelper {
  /// Get category by name from the CategoryBloc
  static ExpenseCategory? getCategoryByName(
      BuildContext context,
      String name,
      bool isExpense,
      ) {
    final categoryState = context.read<CategoryBloc>().state;
    if (categoryState is CategoryLoaded) {
      return categoryState.getCategoryByName(name, isExpense);
    }
    return null;
  }

  /// Get all expense category names from the CategoryBloc
  static List<String> getExpenseCategoryNames(BuildContext context) {
    final categoryState = context.read<CategoryBloc>().state;
    if (categoryState is CategoryLoaded) {
      return categoryState.expenseCategoryNames;
    }
    return [];
  }

  /// Get all income category names from the CategoryBloc
  static List<String> getIncomeCategoryNames(BuildContext context) {
    final categoryState = context.read<CategoryBloc>().state;
    if (categoryState is CategoryLoaded) {
      return categoryState.incomeCategoryNames;
    }
    return [];
  }
}

