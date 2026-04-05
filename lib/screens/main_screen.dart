import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'transactions_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'add_edit_transaction_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  final _dashKey = GlobalKey<DashboardScreenState>();
  final _txKey = GlobalKey<TransactionsScreenState>();
  final _reportsKey = GlobalKey<ReportsScreenState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardScreen(key: _dashKey),
      TransactionsScreen(key: _txKey),
      ReportsScreen(key: _reportsKey),
      const SettingsScreen(),
    ];
  }

  static const _titles = ['Dashboard', 'Transactions', 'Reports', 'Settings'];
  static const _icons = [
    Icons.dashboard_rounded,
    Icons.receipt_long_rounded,
    Icons.bar_chart_rounded,
    Icons.settings_rounded,
  ];

  void _select(int i) {
    setState(() => _index = i);
    Navigator.pop(context);
    // Reload data each time user navigates to a tab so settings changes propagate
    if (i == 0) _dashKey.currentState?.refresh();
    if (i == 1) _txKey.currentState?.refresh();
    if (i == 2) _reportsKey.currentState?.refresh();
  }

  Future<void> _addTransaction() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddEditTransactionScreen()),
    );
    if (added == true) {
      _dashKey.currentState?.refresh();
      _txKey.currentState?.refresh();
      _reportsKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        title: Text(_titles[_index],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: cs.primary),
              accountName: const Text('FinTrack',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              accountEmail: const Text('Personal Finance Manager'),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.account_balance_wallet,
                    color: cs.primary, size: 32),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: List.generate(
                  4,
                  (i) => _DrawerTile(
                    icon: _icons[i],
                    label: _titles[i],
                    selected: _index == i,
                    onTap: () => _select(i),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('v1.0.0', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButton: _index < 2
          ? FloatingActionButton.extended(
              onPressed: _addTransaction,
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: selected ? cs.primary : null),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          color: selected ? cs.primary : null,
        ),
      ),
      selected: selected,
      selectedTileColor: cs.primaryContainer.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: onTap,
    );
  }
}
