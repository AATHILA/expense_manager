import 'package:equatable/equatable.dart';
import '../../models/budget.dart';

abstract class BudgetState extends Equatable {
  const BudgetState();

  @override
  List<Object> get props => [];
}

class BudgetInitial extends BudgetState {
  const BudgetInitial();
}

class BudgetLoading extends BudgetState {
  const BudgetLoading();
}

class BudgetLoaded extends BudgetState {
  final List<Budget> budgets;

  const BudgetLoaded(this.budgets);

  @override
  List<Object> get props => [budgets];

  // Helper methods
  Budget? getBudgetForCategory(String category, int month, int year) {
    try {
      return budgets.firstWhere(
            (b) => b.category == category && b.month == month && b.year == year,
      );
    } catch (e) {
      return null;
    }
  }

  bool isOverBudget(String category, int month, int year, double spent) {
    final budget = getBudgetForCategory(category, month, year);
    if (budget == null) return false;
    return spent > budget.limit;
  }

  bool isNearBudget(String category, int month, int year, double spent) {
    final budget = getBudgetForCategory(category, month, year);
    if (budget == null) return false;
    return spent >= budget.limit * 0.8 && spent <= budget.limit;
  }

  double getBudgetStatus(String category, int month, int year, double spent) {
    final budget = getBudgetForCategory(category, month, year);
    if (budget == null) return 0.0;
    return (spent / budget.limit) * 100;
  }

  List<Budget> getCurrentMonthBudgets() {
    final now = DateTime.now();
    return budgets
        .where((b) => b.month == now.month && b.year == now.year)
        .toList();
  }
}

class BudgetError extends BudgetState {
  final String message;

  const BudgetError(this.message);

  @override
  List<Object> get props => [message];
}

