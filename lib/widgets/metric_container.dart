import 'package:flutter/material.dart';

class MetricContainer extends StatefulWidget {

  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  const MetricContainer(BuildContext context, {
    super.key,
    required this.label,
    required this.amount,
    required this.icon,
    required this.color
  });

  @override
  State<MetricContainer> createState() => _MetricContainerState();
}

class _MetricContainerState extends State<MetricContainer> {
  @override

  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2), // Lighter background
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, color: widget.color, size: 16),
              const SizedBox(width: 4),
              Text(
               widget.label,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '₹${widget.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

