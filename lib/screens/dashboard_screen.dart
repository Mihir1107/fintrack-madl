import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../models/budget_model.dart';
import 'add_edit_transaction_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final _db = DatabaseHelper();

  Map<String, double> _total = {'income': 0, 'expense': 0, 'balance': 0};
  Map<String, double> _monthly = {'income': 0, 'expense': 0, 'balance': 0};
  List<TransactionModel> _recent = [];
  List<CategoryModel> _categories = [];
  List<BudgetModel> _budgets = [];
  Map<int, double> _catExpenses = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final month = DateFormat('yyyy-MM').format(DateTime.now());
    final results = await Future.wait([
      _db.getTotalSummary(),
      _db.getMonthlySummary(month),
      _db.getRecentTransactions(5),
      _db.getCategories(),
      _db.getBudgets(month),
      _db.getCategoryExpenses(month),
    ]);
    if (!mounted) return;
    setState(() {
      _total = results[0] as Map<String, double>;
      _monthly = results[1] as Map<String, double>;
      _recent = results[2] as List<TransactionModel>;
      _categories = results[3] as List<CategoryModel>;
      _budgets = results[4] as List<BudgetModel>;
      _catExpenses = results[5] as Map<int, double>;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final month = DateFormat('MMMM yyyy').format(DateTime.now());

    return RefreshIndicator(
      onRefresh: refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BalanceCard(total: _total, monthly: _monthly, fmt: fmt, month: month),
            const SizedBox(height: 24),

            if (_budgets.isNotEmpty) ...[
              _SectionHeader(title: 'Budget Progress', subtitle: month),
              const SizedBox(height: 10),
              ..._budgets.map((b) => _BudgetCard(
                    budget: b,
                    category: _cat(b.categoryId),
                    spent: _catExpenses[b.categoryId] ?? 0,
                    fmt: fmt,
                  )),
              const SizedBox(height: 24),
            ],

            _SectionHeader(
                title: 'Recent Transactions',
                subtitle: _recent.isEmpty ? '' : 'Pull to refresh'),
            const SizedBox(height: 10),
            if (_recent.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No transactions yet.\nTap + to add one!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              ..._recent.map((t) => _RecentTile(
                    transaction: t,
                    category: _cat(t.categoryId),
                    fmt: fmt,
                    onTap: () async {
                      final edited = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AddEditTransactionScreen(transaction: t),
                        ),
                      );
                      if (edited == true) refresh();
                    },
                  )),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final Map<String, double> total;
  final Map<String, double> monthly;
  final NumberFormat fmt;
  final String month;

  const _BalanceCard(
      {required this.total,
      required this.monthly,
      required this.fmt,
      required this.month});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final balance = total['balance'] ?? 0;
    final shortFmt = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00695C),
            const Color(0xFF00897B),
            Color.lerp(const Color(0xFF00897B), const Color(0xFF26C6DA), 0.6)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: cs.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Total Balance',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(fmt.format(balance),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(month,
              style: const TextStyle(
                  color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 20),
          // Income / Expense mini-chips inside the card
          Row(
            children: [
              Expanded(
                  child: _BalanceChip(
                icon: Icons.arrow_downward_rounded,
                label: 'Income',
                value: shortFmt.format(monthly['income'] ?? 0),
                iconColor: const Color(0xFF69F0AE),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _BalanceChip(
                icon: Icons.arrow_upward_rounded,
                label: 'Expense',
                value: shortFmt.format(monthly['expense'] ?? 0),
                iconColor: const Color(0xFFFF8A80),
              )),
            ],
          ),
        ],
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _BalanceChip(
      {required this.icon,
      required this.label,
      required this.value,
      required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 10)),
              Text(value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}



class _BudgetCard extends StatelessWidget {
  final BudgetModel budget;
  final CategoryModel? category;
  final double spent;
  final NumberFormat fmt;

  const _BudgetCard(
      {required this.budget,
      this.category,
      required this.spent,
      required this.fmt});

  @override
  Widget build(BuildContext context) {
    final progress = (spent / budget.amount).clamp(0.0, 1.0);
    final over = spent > budget.amount;
    final barColor = over
        ? Colors.red
        : (progress > 0.8 ? Colors.orange : Colors.green);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                if (category != null)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: category!.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(category!.icon,
                        size: 18, color: category!.color),
                  ),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(category?.name ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.w500))),
                Text(
                  '${fmt.format(spent)} / ${fmt.format(budget.amount)}',
                  style: TextStyle(
                      fontSize: 11,
                      color: barColor,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 7,
              borderRadius: BorderRadius.circular(4),
            ),
            if (over)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Over budget by ${fmt.format(spent - budget.amount)}',
                  style: const TextStyle(color: Colors.red, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final TransactionModel transaction;
  final CategoryModel? category;
  final NumberFormat fmt;
  final VoidCallback onTap;

  const _RecentTile(
      {required this.transaction,
      this.category,
      required this.fmt,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final amountColor = isIncome ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final iconColor = category?.color ?? amountColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
            left: BorderSide(
                color: amountColor.withValues(alpha: 0.6), width: 3)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
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
        title: Text(transaction.title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          DateFormat('MMM d, yyyy').format(transaction.date),
          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isIncome ? '+' : '-'}${fmt.format(transaction.amount)}',
              style: TextStyle(
                  color: amountColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
            const SizedBox(height: 2),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: amountColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isIncome ? 'IN' : 'OUT',
                style: TextStyle(
                    fontSize: 9,
                    color: amountColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
