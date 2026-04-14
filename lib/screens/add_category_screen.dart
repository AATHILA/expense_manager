import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../blocs/category/category_bloc.dart';
import '../blocs/category/category_event.dart';
import '../models/category.dart';
import '../blocs/transaction/transaction_bloc.dart';
import '../blocs/transaction/transaction_event.dart';
import '../blocs/budget/budget_bloc.dart';
import '../blocs/budget/budget_event.dart';
import '../services/storage_service.dart';
import '../services/storage_services.dart';

class AddCategoryScreen extends StatefulWidget {
  final ExpenseCategory? category;

  const AddCategoryScreen({super.key, this.category});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isExpense = true;
  IconData _selectedIcon = Icons.category;
  Color _selectedColor = Colors.blue;
  bool _isLoading = false;

  // Available icons for categories
  final List<IconData> _availableIcons = [
    Icons.restaurant,
    Icons.flight,
    Icons.receipt_long,
    Icons.shopping_bag,
    Icons.movie,
    Icons.local_hospital,
    Icons.school,
    Icons.directions_car,
    Icons.home,
    Icons.phone,
    Icons.wifi,
    Icons.electric_bolt,
    Icons.water_drop,
    Icons.sports_esports,
    Icons.fitness_center,
    Icons.pets,
    Icons.child_care,
    Icons.local_gas_station,
    Icons.local_cafe,
    Icons.fastfood,
    Icons.account_balance_wallet,
    Icons.business,
    Icons.trending_up,
    Icons.savings,
    Icons.attach_money,
    Icons.more_horiz,
  ];

  // Available colors for categories
  final List<Color> _availableColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _isExpense = widget.category!.isExpense;
      _selectedIcon = widget.category!.icon;
      _selectedColor = widget.category!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category == null ? 'Add Category' : 'Edit Category'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Category Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a category name';
                }
                return null;
              },
              onChanged: (value) {
                // Clear validation errors when user types
                _formKey.currentState?.validate();
              },
            ),
            const SizedBox(height: 16),

            // Type Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category Type',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: true,
                          label: Text('Expense'),
                          icon: Icon(Icons.arrow_upward),
                        ),
                        ButtonSegment(
                          value: false,
                          label: Text('Income'),
                          icon: Icon(Icons.arrow_downward),
                        ),
                      ],
                      selected: {_isExpense},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          _isExpense = newSelection.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Icon Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Icon',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _availableIcons.length,
                        itemBuilder: (context, index) {
                          final icon = _availableIcons[index];
                          final isSelected = icon == _selectedIcon;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedIcon = icon;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _selectedColor.withValues(alpha: 0.3)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? _selectedColor : Colors.grey,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                icon,
                                color: isSelected ? _selectedColor : Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Color Selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Color',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableColors.map((color) {
                        final isSelected = color == _selectedColor;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                            });
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Preview
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preview',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _selectedColor.withValues(alpha: 0.2),
                        child: Icon(_selectedIcon, color: _selectedColor),
                      ),
                      title: Text(_nameController.text.isEmpty
                          ? 'Category Name'
                          : _nameController.text),
                      subtitle: Text(_isExpense ? 'Expense' : 'Income'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveCategory,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(widget.category == null ? 'Add Category' : 'Update Category'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Check for duplicate category name
      final categoryName = _nameController.text.trim();
      final isDuplicate = await _checkDuplicateCategoryName(categoryName);

      if (isDuplicate) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'A ${_isExpense ? "expense" : "income"} category with the name "$categoryName" already exists',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final category = ExpenseCategory(
        id: widget.category?.id ?? const Uuid().v4(),
        name: categoryName,
        iconCodePoint: _selectedIcon.codePoint,
        colorValue: _selectedColor.toARGB32(),
        isExpense: _isExpense,
        isDefault: widget.category?.isDefault ?? false,
      );

      if (!mounted) return;

      if (widget.category == null) {
        context.read<CategoryBloc>().add(AddCategory(category));
      } else {
        // When updating a category, update it in the database first
        // This will cascade the name change to transactions and budgets
        await StorageService.updateCategory(category);

        // Then reload all blocs to reflect the changes
        if (!mounted) return;
        context.read<CategoryBloc>().add(LoadCategories());
        context.read<TransactionBloc>().add(const LoadTransactions());
        context.read<BudgetBloc>().add(const LoadBudgets());
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.category == null
                ? 'Category added successfully'
                : 'Category updated successfully',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _checkDuplicateCategoryName(String name) async {
    final categories = await StorageService.getCategoriesByType(_isExpense);

    // If editing, exclude the current category from duplicate check
    final currentCategoryId = widget.category?.id;

    return categories.any((cat) =>
    cat.name.toLowerCase() == name.toLowerCase() &&
        cat.id != currentCategoryId
    );
  }
}

