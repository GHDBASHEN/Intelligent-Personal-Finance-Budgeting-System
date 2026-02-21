import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Dashboard')), body: const Center(child: Text('Dashboard Analytics')));
}

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Transactions')), body: const Center(child: Text('Transaction List')));
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Settings')), body: const Center(child: Text('Settings & Mock API')));
}
