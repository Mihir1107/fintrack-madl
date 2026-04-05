import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import 'add_edit_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => TransactionsScreenState();
}

class TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseHelper();
  late final TabController _tab;

  List<TransactionModel> _all = [];
  List<TransactionModel> _income = [];
  List<TransactionModel> _expense = [];
  List<CategoryModel> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    refresh();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final results = await Future.wait([
      _db.getTransactions(),
      _db.getTransactions(type: 'income'),
      _db.getTransactions(type: 'expense'),
      _db.getCategories(),
    ]);
    if (!mounted) return;
    setState(() {
      _all = results[0] as List<TransactionModel>;
      _income = results[1] as List<TransactionModel>;
      _expense = results[2] as List<TransactionModel>;
      _categories = results[3] as List<CategoryModel>;
      _loading = false;
    });
  }

  CategoryModel? _cat(int? id) {
    if (id == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _delete(TransactionModel t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text('Delete "${t.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _db.deleteTransaction(t.id!);
      refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _edit(TransactionModel t) async {
    final edited = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTransactionScreen(
          transaction: t,
          heroTag: 'tx_icon_${t.id}',
        ),
      ),
    );
    if (edited == true) refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Income'),
            Tab(text: 'Expenses'),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tab,
                  children: [
                    _TxList(
                        txs: _all,
                        cat: _cat,
                        onEdit: _edit,
                        onDelete: _delete),
                    _TxList(
                        txs: _income,
                        cat: _cat,
                        onEdit: _edit,
                        onDelete: _delete),
                    _TxList(
                        txs: _expense,
                        cat: _cat,
                        onEdit: _edit,
                        onDelete: _delete),
                  ],
                ),
        ),
      ],
    );
  }
}

// ── Transaction list grouped by date ─────────────────────────────────────────

class _TxList extends StatelessWidget {
  final List<TransactionModel> txs;
  final CategoryModel? Function(int?) cat;
  final Future<void> Function(TransactionModel) onEdit;
  final Future<void> Function(TransactionModel) onDelete;

  const _TxList(
      {required this.txs,
      required this.cat,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (txs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No transactions',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    // Group transactions by date (yyyy-MM-dd)
    final grouped = <String, List<TransactionModel>>{};
    for (final t in txs) {
      final key = DateFormat('yyyy-MM-dd').format(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: grouped.length,
      itemBuilder: (_, i) {
        final dateKey = grouped.keys.elementAt(i);
        final dayTxs = grouped[dateKey]!;
        final dayNet = dayTxs.fold(
            0.0,
            (sum, t) =>
                sum + (t.type == 'income' ? t.amount : -t.amount));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 6),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d')
                        .format(DateTime.parse(dateKey)),
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.grey[700]),
                  ),
                  Text(
                    '${dayNet >= 0 ? '+' : ''}${fmt.format(dayNet)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: dayNet >= 0
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFC62828),
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ...dayTxs.map((t) => _TxCard(
                  transaction: t,
                  category: cat(t.categoryId),
                  fmt: fmt,
                  onEdit: () => onEdit(t),
                  onDelete: () => onDelete(t),
                )),
          ],
        );
      },
    );
  }
}

// ── Single transaction card with Hero ────────────────────────────────────────

class _TxCard extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final NumberFormat fmt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TxCard({
    required this.transaction,
    this.category,
    required this.fmt,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final amountColor = isIncome ? Colors.green : Colors.red;
    final iconColor = category?.color ?? amountColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
            left: BorderSide(
                color: amountColor.withValues(alpha: 0.7), width: 3)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: ListTile(
        onTap: onEdit,
        onLongPress: onDelete,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        // Hero animates the category icon into the edit screen header
        leading: Hero(
          tag: 'tx_icon_${transaction.id}',
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              category?.icon ??
                  (isIncome
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded),
              color: iconColor,
            ),
          ),
        ),
        title: Text(transaction.title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Row(
          children: [
            if (category != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(category!.name,
                    style: TextStyle(
                        fontSize: 10,
                        color: iconColor,
                        fontWeight: FontWeight.w600)),
              ),
            if (category != null &&
                transaction.notes?.isNotEmpty == true)
              const Text('  ·  ',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
            if (transaction.notes?.isNotEmpty == true)
              Flexible(
                child: Text(
                  transaction.notes!,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'}${fmt.format(transaction.amount)}',
          style: TextStyle(
              color: amountColor,
              fontWeight: FontWeight.bold,
              fontSize: 14),
        ),
      ),
    );
  }
}
