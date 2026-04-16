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
              onTap: () => ref.read(authProvider.notifier).logout(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToCSV(BuildContext context, List<TransactionEntity> transactions, WidgetRef ref) async {
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
      
      // Automatically find the Downloads location
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        // Fallback for some Android versions if the direct path is inaccessible
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

      // Final fallback to documents if Downloads is still null
      directory ??= await getApplicationDocumentsDirectory();

      final String path = '${directory.path}/$fileName';
      final file = File(path);
      await file.writeAsString(csv);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved to: $path'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );

        // Trigger system-level tray notification with the file path as payload
        ref.read(notificationServiceProvider).showDownloadNotification(
          'Export Successful',
          'Tap to open your financial summary',
          payload: path,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    }
  }
}
