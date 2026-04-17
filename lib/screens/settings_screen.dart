import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/theme/theme_bloc.dart';
import '../blocs/theme/theme_event.dart';
import '../blocs/theme/theme_state.dart';

import '../models/currency.dart';
import '../services/currency_services.dart';
import '../services/google_drive_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSignedIn = false;
  String? _userEmail;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSignInStatus();
  }

  Future<void> _checkSignInStatus() async {
    final user = await GoogleDriveService.getCurrentUser();
    if (mounted) {
      setState(() {
        _isSignedIn = user != null;
        _userEmail = user?.email;
      });
    }
  }

  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final account = await GoogleDriveService.signIn();
      if (account != null && mounted) {
        setState(() {
          _isSignedIn = true;
          _userEmail = account.email;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Signed in as ${account.email}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    try {
      await GoogleDriveService.signOut();
      if (mounted) {
        setState(() {
          _isSignedIn = false;
          _userEmail = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed out successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign out failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleBackup() async {
    if (!_isSignedIn) {
      await _handleSignIn();
      if (!_isSignedIn) return;
    }

    setState(() => _isLoading = true);
    try {
      final message = await GoogleDriveService.backupToGoogleDrive();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
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

  Future<void> _handleRestore() async {
    if (!_isSignedIn) {
      await _handleSignIn();
      if (!_isSignedIn) return;
    }

    if (!mounted) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: const Text(
          'This will replace all current data with the backup. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final message = await GoogleDriveService.restoreFromGoogleDrive();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
        // Reload the app to reflect restored data
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          const SizedBox(height: 8),

          // Categories Management
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('Manage Categories'),
            subtitle: const Text('Add, edit, or delete categories'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/categories');
            },
          ),

          const Divider(),

          // Currency Settings
          FutureBuilder<String?>(
            future: CurrencyService.getCurrencySymbol(),
            builder: (context, snapshot) {
              final currencySymbol = snapshot.data ?? '₹';
              return ListTile(
                leading: const Icon(Icons.currency_exchange),
                title: const Text('Currency'),
                subtitle: Text('Current: $currencySymbol'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final result = await showDialog<Currency>(
                    context: context,
                    builder: (context) => const _CurrencySelectionDialog(),
                  );
                  if (result != null) {
                    await CurrencyService.setCurrency(result.code, result.symbol);
                    if (mounted) {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Currency changed to ${result.name}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                },
              );
            },
          ),

          const Divider(),

          // Theme Settings
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) {
              final isDarkMode = state.themeMode == ThemeMode.dark;
              return SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Toggle between light and dark theme'),
                secondary: Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                ),
                value: isDarkMode,
                onChanged: (value) {
                  context.read<ThemeBloc>().add(const ToggleTheme());
                },
              );
            },
          ),

          const Divider(),

          // Notification Settings
          FutureBuilder<Map<String, dynamic>>(
            future: NotificationService().getNotificationPreferences(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const ListTile(
                  title: Text('Loading notification settings...'),
                );
              }

              final prefs = snapshot.data!;
              final enabled = prefs['enabled'] as bool;
              final hour = prefs['hour'] as int;
              final minute = prefs['minute'] as int;
              final timeStr =
                  '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

              return Column(
                children: [
                  SwitchListTile(
                    title: const Text('Daily Reminders'),
                    subtitle: Text(
                      enabled ? 'Enabled at $timeStr' : 'Disabled',
                    ),
                    secondary: Icon(
                      enabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                    ),
                    value: enabled,
                    onChanged: (value) async {
                      if (value) {
                        // Request permissions when enabling
                        final permissionGranted = await NotificationService()
                            .requestPermissionsWithDialog(context);
                        if (!permissionGranted) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                Text('Notification permission denied'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                          return;
                        }
                      }
                      await NotificationService().enableReminders(value);
                      if (mounted) {
                        setState(() {});
                      }
                    },
                  ),
                  if (enabled)
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Reminder Time'),
                      subtitle: Text('Current: $timeStr'),
                      trailing:
                      const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(hour: hour, minute: minute),
                        );
                        if (picked != null) {
                          await NotificationService().updateDailyReminderTime(
                            picked.hour,
                            picked.minute,
                          );
                          if (mounted) {
                            setState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Reminder time updated to ${picked.format(context)}',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  if (enabled)
                    ListTile(
                      leading: const Icon(Icons.notification_important),
                      title: const Text('Test Notification'),
                      subtitle: const Text('Send a test notification now'),
                      onTap: () async {
                        await NotificationService().showTestNotification();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Test notification sent!'),
                              backgroundColor: Colors.blue,
                            ),
                          );
                        }
                      },
                    ),
                ],
              );
            },
          ),

          const Divider(),

          // Backup & Restore Section
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Backup & Restore',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),

          // Google Account Status
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: Text(_isSignedIn ? 'Google Account' : 'Sign in to Google'),
            subtitle: Text(_isSignedIn ? _userEmail ?? 'Signed in' : 'Required for backup & restore'),
            trailing: _isSignedIn
                ? TextButton(
              onPressed: _handleSignOut,
              child: const Text('Sign Out'),
            )
                : null,
            onTap: _isSignedIn ? null : _handleSignIn,
          ),

          // Backup Button
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('Backup to Google Drive'),
            subtitle: const Text('Save your data to Google Drive'),
            enabled: _isSignedIn,
            onTap: _handleBackup,
          ),

          // Restore Button
          ListTile(
            leading: const Icon(Icons.cloud_download),
            title: const Text('Restore from Google Drive'),
            subtitle: const Text('Restore your data from Google Drive'),
            enabled: _isSignedIn,
            onTap: _handleRestore,
          ),

          const Divider(),

          // About Section
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: const Text('Smart Personal Finance & Expense Tracker'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Expense Manager',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.account_balance_wallet, size: 48),
                children: [
                  const Text(
                    'A comprehensive expense tracking app with budgeting features.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// Currency Selection Dialog
class _CurrencySelectionDialog extends StatefulWidget {
  const _CurrencySelectionDialog({super.key});

  @override
  State<_CurrencySelectionDialog> createState() => _CurrencySelectionDialogState();
}

class _CurrencySelectionDialogState extends State<_CurrencySelectionDialog> {
  String _searchQuery = '';

  List<Currency> get _filteredCurrencies {
    if (_searchQuery.isEmpty) {
      return Currencies.popular;
    }
    return Currencies.popular.where((currency) {
      final query = _searchQuery.toLowerCase();
      return currency.name.toLowerCase().contains(query) ||
          currency.code.toLowerCase().contains(query) ||
          currency.symbol.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.currency_exchange, size: 28),
                      const SizedBox(width: 12),
                      const Text(
                        'Select Currency',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search currency...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Currency list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _filteredCurrencies.length,
                itemBuilder: (context, index) {
                  final currency = _filteredCurrencies[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        currency.symbol,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(currency.name),
                    subtitle: Text(currency.code),
                    onTap: () => Navigator.pop(context, currency),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
