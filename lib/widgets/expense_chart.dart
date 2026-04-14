import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/currency_services.dart';
import '../services/storage_services.dart';


enum ChartType { pie, bar }

class ExpenseChart extends StatefulWidget {
  final Map<String, double> expensesByCategory;
  final List<Transaction> allTransactions;

  const ExpenseChart({
    super.key,
    required this.expensesByCategory,
    required this.allTransactions,
  });

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart> {
  Map<String, ExpenseCategory> _categoryMap = {};
  bool _isLoading = true;
  ChartType _selectedChartType = ChartType.pie;
  int _touchedIndex = -1;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categories = await StorageService.getAllCategoriesAsync();
    setState(() {
      _categoryMap = {for (var cat in categories) cat.name: cat};
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final filteredExpenses = _selectedChartType == ChartType.pie
        ? _getFilteredExpensesByCategory()
        : widget.expensesByCategory;

    if (filteredExpenses.isEmpty && _selectedChartType == ChartType.pie) {
      return Card(
        child: Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No expense data available for ${DateFormat('MMMM yyyy').format(_selectedMonth)}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart Type Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedChartType == ChartType.pie
                      ? 'Expenses by Category'
                      : 'Last 6 Months Expenses',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButton<ChartType>(
                  value: _selectedChartType,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(
                      value: ChartType.pie,
                      child: Row(
                        children: [
                          Icon(Icons.pie_chart, size: 20),
                          SizedBox(width: 8),
                          Text('Pie Chart'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: ChartType.bar,
                      child: Row(
                        children: [
                          Icon(Icons.bar_chart, size: 20),
                          SizedBox(width: 8),
                          Text('Bar Chart'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (ChartType? value) {
                    if (value != null) {
                      setState(() {
                        _selectedChartType = value;
                        _touchedIndex = -1;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Month Selector (only for pie chart)
            if (_selectedChartType == ChartType.pie)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month - 1,
                        );
                      });
                    },
                  ),
                  InkWell(
                    onTap: () => _showMonthPicker(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 18,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMMM yyyy').format(_selectedMonth),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _isCurrentOrFutureMonth() ? null : () {
                      setState(() {
                        _selectedMonth = DateTime(
                          _selectedMonth.year,
                          _selectedMonth.month + 1,
                        );
                      });
                    },
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Chart Display
            SizedBox(
              height: 200,
              child: _selectedChartType == ChartType.pie
                  ? _buildPieChart(context)
                  : _buildBarChart(context),
            ),
            const SizedBox(height: 16),

            // Legend (only for pie chart)
            if (_selectedChartType == ChartType.pie)
              _buildLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(BuildContext context) {
    return FutureBuilder<List<PieChartSectionData>>(
      future: _buildPieChartSections(context),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return PieChart(
          PieChartData(
            sections: snapshot.data!,
            sectionsSpace: 2,
            centerSpaceRadius: 40,
            borderData: FlBorderData(show: false),
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                setState(() {
                  if (!event.isInterestedForInteractions ||
                      pieTouchResponse == null ||
                      pieTouchResponse.touchedSection == null) {
                    _touchedIndex = -1;
                    return;
                  }
                  _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                });
              },
            ),
          ),
        );
      },
    );
  }

  Future<List<PieChartSectionData>> _buildPieChartSections(BuildContext context) async {
    final filteredExpenses = _getFilteredExpensesByCategory();

    if (filteredExpenses.isEmpty) {
      return [];
    }

    final total = filteredExpenses.values.fold(0.0, (sum, value) => sum + value);
    final currencySymbol = await CurrencyService.getCurrencySymbol();
    final currencyFormatter = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 0);
    int index = 0;

    return filteredExpenses.entries.map((entry) {
      final isTouched = index == _touchedIndex;
      final percentage = (entry.value / total) * 100;
      final category = _categoryMap[entry.key];
      index++;

      return PieChartSectionData(
        value: entry.value,
        title: isTouched
            ? '${entry.key}\n${currencyFormatter.format(entry.value)}'
            : '${percentage.toStringAsFixed(1)}%',
        color: category?.color ?? Colors.grey,
        radius: isTouched ? 65 : 55,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildBarChart(BuildContext context) {
    return FutureBuilder<String>(
      future: CurrencyService.getCurrencySymbol(),
      builder: (context, snapshot) {
        final currencySymbol = snapshot.data ?? '₹';
        final currencyFormatter = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 0);
        final monthlyData = _calculateLast6MonthsExpenses();

        if (monthlyData.isEmpty) {
          return Center(
            child: Text(
              'No expense data available',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        final maxY = monthlyData.values.reduce((a, b) => a > b ? a : b);

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY * 1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final monthYear = monthlyData.keys.elementAt(group.x.toInt());
                  return BarTooltipItem(
                    '$monthYear\n${currencyFormatter.format(rod.toY)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value.toInt() >= 0 && value.toInt() < monthlyData.length) {
                      final monthYear = monthlyData.keys.elementAt(value.toInt());
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          monthYear,
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      currencyFormatter.format(value),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(
              monthlyData.length,
                  (index) => BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: monthlyData.values.elementAt(index),
                    color: Theme.of(context).colorScheme.primary,
                    width: 20,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Map<String, double> _calculateLast6MonthsExpenses() {
    final Map<String, double> monthlyExpenses = {};
    final now = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('MMM yy').format(month);

      final total = widget.allTransactions
          .where((t) =>
      t.type == TransactionType.expense &&
          t.date.year == month.year &&
          t.date.month == month.month)
          .fold(0.0, (sum, t) => sum + t.amount);

      monthlyExpenses[monthKey] = total;
    }

    return monthlyExpenses;
  }

  Widget _buildLegend(BuildContext context) {
    final filteredExpenses = _getFilteredExpensesByCategory();

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: filteredExpenses.entries.map((entry) {
        final category = _categoryMap[entry.key];

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: category?.color ?? Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              entry.key,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      }).toList(),
    );
  }

  Map<String, double> _getFilteredExpensesByCategory() {
    final Map<String, double> categoryExpenses = {};

    for (var transaction in widget.allTransactions) {
      if (transaction.type == TransactionType.expense &&
          transaction.date.year == _selectedMonth.year &&
          transaction.date.month == _selectedMonth.month) {
        categoryExpenses[transaction.category] =
            (categoryExpenses[transaction.category] ?? 0) + transaction.amount;
      }
    }

    return categoryExpenses;
  }

  bool _isCurrentOrFutureMonth() {
    final now = DateTime.now();
    return _selectedMonth.year >= now.year && _selectedMonth.month >= now.month;
  }

  Future<void> _showMonthPicker(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedMonth.isAfter(now) ? now : _selectedMonth,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
      helpText: 'Select Month',
    );

    if (picked != null) {
      setState(() {
        _selectedMonth = DateTime(picked.year, picked.month);
      });
    }
  }
}

