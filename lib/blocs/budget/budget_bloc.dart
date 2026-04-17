import 'package:flutter_bloc/flutter_bloc.dart';

import '../../services/storage_service.dart';
import 'budget_event.dart';
import 'budget_state.dart';

class BudgetBloc extends Bloc<BudgetEvent, BudgetState> {
  BudgetBloc() : super(const BudgetInitial()) {
    on<LoadBudgets>(_onLoadBudgets);
    on<AddBudget>(_onAddBudget);
    on<UpdateBudget>(_onUpdateBudget);
    on<DeleteBudget>(_onDeleteBudget);
  }

  Future<void> _onLoadBudgets(
      LoadBudgets event,
      Emitter<BudgetState> emit,
      ) async {
    try {
      emit(const BudgetLoading());
      final budgets = await StorageService.getAllBudgetsAsync();
      emit(BudgetLoaded(budgets));
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  Future<void> _onAddBudget(
      AddBudget event,
      Emitter<BudgetState> emit,
      ) async {
    try {
      await StorageService.addBudget(event.budget);
      final budgets = await StorageService.getAllBudgetsAsync();
      emit(BudgetLoaded(budgets));
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  Future<void> _onUpdateBudget(
      UpdateBudget event,
      Emitter<BudgetState> emit,
      ) async {
    try {
      await StorageService.updateBudget(event.budget);
      final budgets = await StorageService.getAllBudgetsAsync();
      emit(BudgetLoaded(budgets));
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }

  Future<void> _onDeleteBudget(
      DeleteBudget event,
      Emitter<BudgetState> emit,
      ) async {
    try {
      await StorageService.deleteBudget(event.id);
      final budgets = await StorageService.getAllBudgetsAsync();
      emit(BudgetLoaded(budgets));
    } catch (e) {
      emit(BudgetError(e.toString()));
    }
  }
}

