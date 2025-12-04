import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/currency_services.dart';

class BudgetBreachAlertDialog extends StatefulWidget {
  final String category;
  final double budgetLimit;
  final double currentSpent;
  final double newAmount;
  final int month;
  final int year;
  final VoidCallback onContinue;
  final Function(bool skipFuture) onContinueWithPreference;

  const BudgetBreachAlertDialog({
    super.key,
    required this.category,
    required this.budgetLimit,
    required this.currentSpent,
    required this.newAmount,
    required this.month,
    required this.year,
    required this.onContinue,
    required this.onContinueWithPreference,
  });

  @override
  State<BudgetBreachAlertDialog> createState() => _BudgetBreachAlertDialogState();
}

class _BudgetBreachAlertDialogState extends State<BudgetBreachAlertDialog> {
  bool _skipFutureAlerts = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: CurrencyService.getCurrencySymbol(),
      builder: (context, snapshot) {
        final currencySymbol = snapshot.data ?? '₹';
        final currencyFormatter = NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);
        final totalAfterTransaction = widget.currentSpent + widget.newAmount;
        final overBudgetAmount = totalAfterTransaction - widget.budgetLimit;
        final percentage = (totalAfterTransaction / widget.budgetLimit * 100).toStringAsFixed(1);
        final monthName = DateFormat('MMMM yyyy').format(DateTime(widget.year, widget.month));

        return AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange[700],
            size: 48,
          ),
          title: const Text(
            'Budget Alert!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Alert message
                Text(
                  'This transaction will exceed your budget for ${widget.category}.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Budget details card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'Budget Limit',
                        currencyFormatter.format(widget.budgetLimit),
                        Colors.blue,
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        'Current Spent',
                        currencyFormatter.format(widget.currentSpent),
                        Colors.grey[700]!,
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        'This Transaction',
                        currencyFormatter.format(widget.newAmount),
                        Colors.grey[700]!,
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        'Total After',
                        currencyFormatter.format(totalAfterTransaction),
                        Colors.orange[700]!,
                        isBold: true,
                      ),
                      const Divider(height: 16),
                      _buildDetailRow(
                        'Over Budget',
                        currencyFormatter.format(overBudgetAmount),
                        Colors.red,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Percentage indicator
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      '$percentage% of budget',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Month info
                Center(
                  child: Text(
                    'For $monthName',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Skip future alerts checkbox
                CheckboxListTile(
                  value: _skipFutureAlerts,
                  onChanged: (value) {
                    setState(() {
                      _skipFutureAlerts = value ?? false;
                    });
                  },
                  title: Text(
                    'Don\'t show this alert again this month',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context, true);
                widget.onContinueWithPreference(_skipFutureAlerts);
              },
              icon: const Icon(Icons.check),
              label: const Text('Continue Anyway'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange[700],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: valueColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

