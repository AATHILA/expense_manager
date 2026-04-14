import 'package:flutter/material.dart';

import '../services/notification_services.dart';


class NotificationSetupScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const NotificationSetupScreen({super.key, this.onComplete});

  @override
  State<NotificationSetupScreen> createState() => _NotificationSetupScreenState();
}

class _NotificationSetupScreenState extends State<NotificationSetupScreen> {
  bool _enableNotifications = true;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _isLoading = false;

  Future<void> _setupNotifications() async {
    setState(() => _isLoading = true);

    try {
      // Request permissions first if enabling
      if (_enableNotifications) {
        final permissionGranted =
        await NotificationService().requestPermissionsWithDialog(context);
        if (!permissionGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification permission denied'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      // Save preferences (this will schedule the notification)
      await NotificationService().saveNotificationPreferences(
        enabled: _enableNotifications,
        hour: _selectedTime.hour,
        minute: _selectedTime.minute,
      );

      if (_enableNotifications) {
        // Small delay to ensure scheduling completed
        await Future.delayed(const Duration(milliseconds: 500));
        await NotificationService().showTestNotification();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_enableNotifications
                ? 'Reminders enabled for ${_selectedTime.format(context)}'
                : 'Reminders disabled'),
            backgroundColor: Colors.green,
          ),
        );
        // Add a small delay before completing to ensure everything is saved
        await Future.delayed(const Duration(milliseconds: 300));
        widget.onComplete?.call();
      }
    } catch (e) {
      print('Error during notification setup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting up notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Daily Reminders'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.notifications_active,
                        size: 48,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Never Forget to Track Expenses',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get daily reminders to record your expenses and stay on top of your finances.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Card(
                child: SwitchListTile(
                  title: const Text('Enable Daily Reminders'),
                  subtitle: const Text(
                    'Receive notifications at your chosen time every day',
                  ),
                  secondary: Icon(
                    _enableNotifications
                        ? Icons.notifications_on
                        : Icons.notifications_off,
                  ),
                  value: _enableNotifications,
                  onChanged: (value) {
                    setState(() => _enableNotifications = value);
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (_enableNotifications) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reminder Time',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _selectTime,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 20,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Choose Time',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _selectedTime.format(context),
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      Icons.access_time,
                                      size: 40,
                                      color: Colors.blue.withOpacity(0.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Text(
                'Benefits',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const _BenefitItem(
                icon: Icons.check_circle_outline,
                title: 'Stay Consistent',
                description: 'Build a habit of tracking expenses daily',
              ),
              const SizedBox(height: 8),
              const _BenefitItem(
                icon: Icons.trending_down,
                title: 'Better Insights',
                description: 'Complete data leads to accurate financial analysis',
              ),
              const SizedBox(height: 8),
              const _BenefitItem(
                icon: Icons.pie_chart_outline,
                title: 'Budget Control',
                description: 'Stay within budget by tracking regularly',
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _setupNotifications,
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                      AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : Text(
                    _enableNotifications ? 'Enable Reminders' : 'Skip',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
