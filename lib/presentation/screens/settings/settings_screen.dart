import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:go_router/go_router.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/infrastructure_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyService = ref.watch(currencyServiceProvider);
    final transactions = ref.watch(transactionProvider).transactions;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text('Exchange Rates (Mock)'),
            subtitle: FutureBuilder<Map<String, dynamic>>(
              future: currencyService.getExchangeRates('USD'),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text('Loading...');
                }
                if (snapshot.hasError) return const Text('Error loading rates');
                final rates = snapshot.data?['rates'] as Map<String, dynamic>?;
                return Text('1 USD = ${(rates?['LKR'] ?? 'N/A')} LKR');
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Export financial summary (CSV)'),
            onTap: () => _exportToCSV(context, transactions),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Scan Receipt (Camera)'),
            onTap: () => context.push('/receipt-scan'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () => ref.read(authProvider.notifier).logout(),
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
