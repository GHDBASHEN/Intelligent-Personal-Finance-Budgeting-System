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
import '../../../data/sources/local/database_helper.dart';  // Add this import

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // Add this method to view database
  void _viewDatabase(BuildContext context) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;
    
    // Get all users
    final users = await db.query('users');
    
    print('\n');
    print('══════════════════════════════════════════════════');
    print('              DATABASE CONTENTS');
    print('══════════════════════════════════════════════════');
    
    print('\n📋 USERS TABLE:');
    print('┌────┬─────────────────────────┬─────────────────────────┐');
    print('│ ID │ Email                   │ Password                │');
    print('├────┼─────────────────────────┼─────────────────────────┤');
    
    for (var user in users) {
      String id = user['id'].toString().padRight(3);
      String email = (user['email'] as String).padRight(23);
      String password = (user['password'] as String).padRight(23);
      print('│ $id │ $email │ $password │');
    }
    
    print('└────┴─────────────────────────┴─────────────────────────┘');
    
    // Get all transactions
    final transactions = await db.query('transactions');
    
    if (transactions.isNotEmpty) {
      print('\n💰 TRANSACTIONS TABLE:');
      print('┌────┬─────────┬──────────────────────┬──────────┐');
      print('│ ID │ Amount  │ Note                  │ Type     │');
      print('├────┼─────────┼──────────────────────┼──────────┤');
      
      for (var tx in transactions) {
        String id = tx['id'].toString().padRight(3);
        String amount = tx['amount'].toString().padRight(7);
        String note = (tx['note'] as String).length > 20 
            ? '${(tx['note'] as String).substring(0, 17)}...' 
            : (tx['note'] as String).padRight(20);
        String type = (tx['type'] as String).padRight(8);
        print('│ $id │ $amount │ $note │ $type │');
      }
      
      print('└────┴─────────┴──────────────────────┴──────────┘');
    }
    
    // Get all categories
    final categories = await db.query('categories');
    
    if (categories.isNotEmpty) {
      print('\n🏷️ CATEGORIES TABLE:');
      print('┌────┬─────────────────┐');
      print('│ ID │ Name            │');
      print('├────┼─────────────────┤');
      
      for (var cat in categories) {
        String id = cat['id'].toString().padRight(3);
        String name = (cat['name'] as String).padRight(15);
        print('│ $id │ $name │');
      }
      
      print('└────┴─────────────────┘');
    }
    
    print('\n══════════════════════════════════════════════════\n');
    
    // Show snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Database printed to console! Check terminal.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyService = ref.watch(currencyServiceProvider);
    final transactions = ref.watch(transactionProvider).transactions;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme and Currency Card
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
          
          // Database Viewer Card (NEW)
          Card(
            color: Colors.blue.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.storage, color: Colors.blue),
              title: const Text('View Database in Console'),
              subtitle: const Text('Check VS Code terminal for all users & passwords'),
              trailing: const Icon(Icons.terminal, color: Colors.blue),
              onTap: () => _viewDatabase(context),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Export CSV Card
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
          
          // Logout Card
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported to Documents: $path')),
    );
  }
}