import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/storage_services.dart';
import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc() : super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<AddCategory>(_onAddCategory);
    on<UpdateCategory>(_onUpdateCategory);
    on<DeleteCategory>(_onDeleteCategory);
    on<FilterCategoriesByType>(_onFilterCategoriesByType);
  }

  Future<void> _onLoadCategories(
      LoadCategories event,
      Emitter<CategoryState> emit,
      ) async {
    emit(CategoryLoading());
    try {
      final categories = await StorageService.getAllCategoriesAsync();
      emit(CategoryLoaded(categories));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> _onAddCategory(
      AddCategory event,
      Emitter<CategoryState> emit,
      ) async {
    try {
      await StorageService.addCategory(event.category);
      final categories = await StorageService.getAllCategoriesAsync();
      emit(CategoryLoaded(categories));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> _onUpdateCategory(
      UpdateCategory event,
      Emitter<CategoryState> emit,
      ) async {
    try {
      await StorageService.updateCategory(event.category);
      final categories = await StorageService.getAllCategoriesAsync();
      emit(CategoryLoaded(categories));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> _onDeleteCategory(
      DeleteCategory event,
      Emitter<CategoryState> emit,
      ) async {
    try {
      // Check if category is in use
      final isInUse = await StorageService.isCategoryInUse(event.name);
      if (isInUse) {
        emit(CategoryError('Cannot delete category "${event.name}" as it is being used in transactions or budgets'));
        // Reload categories to restore state
        final categories = await StorageService.getAllCategoriesAsync();
        emit(CategoryLoaded(categories));
        return;
      }

      await StorageService.deleteCategory(event.id);
      final categories = await StorageService.getAllCategoriesAsync();
      emit(CategoryLoaded(categories));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> _onFilterCategoriesByType(
      FilterCategoriesByType event,
      Emitter<CategoryState> emit,
      ) async {
    if (state is CategoryLoaded) {
      final currentState = state as CategoryLoaded;
      emit(CategoryLoaded(
        currentState.categories,
        filterIsExpense: event.isExpense,
      ));
    }
  }
}

