import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/infrastructure_providers.dart';
import '../../providers/currency_state_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/custom_app_bar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyService = ref.watch(currencyServiceProvider);
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
                  onTap: () => _exportToCSV(context, transactions),
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

  Future<void> _exportToCSV(BuildContext context, List transactions) async {
    List<List<dynamic>> rows = [
      ['Date', 'Note', 'Amount', 'Type'],
    ];

    for (var tx in transactions) {
      rows.add([tx.date.toIso8601String(), tx.note, tx.amount, tx.type.name]);
    }

    String csv = const CsvEncoder().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/finance_summary.csv';
    final file = File(path);
    await file.writeAsString(csv);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('CSV exported to Documents: $path')));

    // In a real device, we would use Share.shareXFiles([XFile(path)]);
  }
}
