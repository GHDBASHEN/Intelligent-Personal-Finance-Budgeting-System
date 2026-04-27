import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/currency_state_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../providers/notification_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(transactionProvider).transactions;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Consumer(
                  builder: (context, ref, child) {
                    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
                    return SwitchListTile(
                      title: const Text('Dark Mode'),
                      secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
                      value: isDarkMode,
                      onChanged: (val) {
                        ref.read(themeModeProvider.notifier).toggleTheme(val);
                      },
                    );
                  },
                ),
                const Divider(),
                Consumer(
                  builder: (context, ref, child) {
                    final currencyState = ref.watch(currencyStateProvider);
                    final availableCurrencies = currencyState.rates.keys.toList()..sort();
                    
                    return ListTile(
                      title: const Text('Target Currency'),
                      subtitle: const Text('View analytics & history in this currency'),
                      leading: const Icon(Icons.currency_exchange),
                      trailing: currencyState.isLoading && availableCurrencies.isEmpty
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : DropdownButton<String>(
                              value: availableCurrencies.contains(currencyState.targetCurrency) 
                                  ? currencyState.targetCurrency 
                                  : null,
                              underline: const SizedBox(),
                              items: availableCurrencies.map((String c) {
                                return DropdownMenuItem<String>(
                                  value: c,
                                  child: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  ref.read(currencyStateProvider.notifier).setTargetCurrency(val);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Currency changed to $val')),
                                    );
                                  }
                                }
                              },
                            ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.file_download, color: Colors.orangeAccent),
                  title: const Text('Export financial summary (CSV)'),
                  onTap: () => _exportToCSV(context, transactions, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Logout', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(authProvider.notifier).logout();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToCSV(BuildContext context, List<TransactionEntity> transactions, WidgetRef ref) async {
    if (transactions.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transactions to export. Add some transactions first!')),
        );
      }
      return;
    }

    try {
      List<List<dynamic>> rows = [
        ['Date', 'Note', 'Amount', 'Type'],
      ];

      for (var tx in transactions) {
        final typeString = tx.type.toString().split('.').last;
        rows.add([
          tx.date.toIso8601String(),
          tx.note,
          tx.amount.toStringAsFixed(2),
          typeString,
        ]);
      }

      String csv = const CsvEncoder().convert(rows);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'finance_summary_$timestamp.csv';
      
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          final list = await getExternalStorageDirectories(type: StorageDirectory.downloads);
          if (list != null && list.isNotEmpty) {
            directory = list.first;
          } else {
            directory = await getExternalStorageDirectory();
          }
        }
      } else {
        directory = await getDownloadsDirectory();
      }

      directory ??= await getApplicationDocumentsDirectory();

      final String path = '${directory.path}/$fileName';
      final file = File(path);
      await file.writeAsString(csv);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${transactions.length} transactions exported to Downloads folder'),
            duration: const Duration(seconds: 3),
          ),
        );

        await ref.read(notificationServiceProvider).showDownloadNotification(
          'Export Successful',
          '${transactions.length} transactions exported to $fileName',
          payload: path,
        );
      }
    } catch (e) {
      if (context.mounted) {
        String errorMessage = 'Failed to export transactions. ';
        if (e.toString().contains('permission')) {
          errorMessage += 'Please grant storage permission to save files.';
        } else if (e.toString().contains('space')) {
          errorMessage += 'Not enough storage space on your device.';
        } else {
          errorMessage += 'Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }
}