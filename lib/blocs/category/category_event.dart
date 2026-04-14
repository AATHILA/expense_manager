import '../../models/category.dart';

abstract class CategoryEvent {}

class LoadCategories extends CategoryEvent {}

class AddCategory extends CategoryEvent {
  final ExpenseCategory category;

  AddCategory(this.category);
}

class UpdateCategory extends CategoryEvent {
  final ExpenseCategory category;

  UpdateCategory(this.category);
}

class DeleteCategory extends CategoryEvent {
  final String id;
  final String name;

  DeleteCategory(this.id, this.name);
}

class FilterCategoriesByType extends CategoryEvent {
  final bool? isExpense;

  FilterCategoriesByType(this.isExpense);
}

