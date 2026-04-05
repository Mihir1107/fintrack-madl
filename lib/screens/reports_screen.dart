import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/category_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => ReportsScreenState();
}

class ReportsScreenState extends State<ReportsScreen> {
  final _db = DatabaseHelper();

  DateTime _month = DateTime.now();
  Map<String, double> _summary = {'income': 0, 'expense': 0, 'balance': 0};
  Map<int, double> _catExp = {};
  List<CategoryModel> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final m = DateFormat('yyyy-MM').format(_month);
    final results = await Future.wait([
      _db.getMonthlySummary(m),
      _db.getCategoryExpenses(m),
      _db.getCategories(),
    ]);
    if (!mounted) return;
    setState(() {
      _summary = results[0] as Map<String, double>;
      _catExp = results[1] as Map<int, double>;
      _categories = results[2] as List<CategoryModel>;
      _loading = false;
    });
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    refresh();
  }

  CategoryModel? _cat(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final monthStr = DateFormat('MMMM yyyy').format(_month);
    final balance = _summary['balance'] ?? 0;

    return Column(
      children: [
        // Month selector
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _shiftMonth(-1)),
              Text(monthStr,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _shiftMonth(1)),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary cards
                      Row(
                        children: [
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Income',
                                  value: _summary['income'] ?? 0,
                                  color: Colors.green,
                                  icon: Icons.arrow_downward_rounded,
                                  fmt: fmt)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: _SummaryCard(
                                  label: 'Expenses',
                                  value: _summary['expense'] ?? 0,
                                  color: Colors.red,
                                  icon: Icons.arrow_upward_rounded,
                                  fmt: fmt)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _SummaryCard(
                        label: 'Net Balance',
                        value: balance,
                        color: balance >= 0 ? Colors.green : Colors.red,
                        icon: balance >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                        fmt: fmt,
                        fullWidth: true,
                      ),
                      const SizedBox(height: 28),

                      // Savings rate
                      if ((_summary['income'] ?? 0) > 0) ...[
                        _SavingsRateCard(
                            income: _summary['income'] ?? 0,
                            expense: _summary['expense'] ?? 0),
                        const SizedBox(height: 28),
                      ],

                      // Expense breakdown
                      const Text('Expense Breakdown',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      if (_catExp.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Text('No expenses recorded this month.',
                                style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      else
                        _CategoryChart(
                            expenses: _catExp, cat: _cat, fmt: fmt),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;
  final NumberFormat fmt;
  final bool fullWidth;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.fmt,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 2),
                Text(fmt.format(value),
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 17)),
              ],
            ),
          ],
        ),
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: card) : card;
  }
}

class _SavingsRateCard extends StatelessWidget {
  final double income;
  final double expense;

  const _SavingsRateCard({required this.income, required this.expense});

  @override
  Widget build(BuildContext context) {
    final rate = ((income - expense) / income).clamp(0.0, 1.0);
    final pct = (rate * 100).toStringAsFixed(1);
    final color = rate >= 0.2
        ? const Color(0xFF2E7D32)
        : (rate >= 0 ? Colors.orange : Colors.red);
    final msg = rate >= 0.2
        ? 'Excellent! Keep it up.'
        : rate >= 0.1
            ? 'Almost there — aim for 20%.'
            : 'You\'re spending more than you earn.';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.savings_outlined, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Savings Rate',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(msg,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              ),
              Text('$pct%',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: color)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: rate,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 9,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  final Map<int, double> expenses;
  final CategoryModel? Function(int) cat;
  final NumberFormat fmt;

  const _CategoryChart(
      {required this.expenses, required this.cat, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final total = expenses.values.fold(0.0, (a, b) => a + b);
    final sorted = expenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sorted.map((entry) {
        final c = cat(entry.key);
        final pct = total > 0 ? entry.value / total : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (c?.color ?? Colors.grey)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  c?.icon ?? Icons.category,
                  color: c?.color ?? Colors.grey,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(c?.name ?? 'Unknown',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        Text(
                          '${fmt.format(entry.value)}  (${(pct * 100).toStringAsFixed(1)}%)',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    LinearProgressIndicator(
                      value: pct,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(
                          c?.color ?? Colors.blue),
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
