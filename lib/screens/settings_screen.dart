import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/category_model.dart';
import '../models/budget_model.dart';
import 'add_edit_category_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final _db = DatabaseHelper();
  late final TabController _tab;

  List<CategoryModel> _categories = [];
  List<BudgetModel> _budgets = [];
  bool _loading = true;

  final String _currentMonth =
      DateFormat('yyyy-MM').format(DateTime.now());
  final String _monthDisplay =
      DateFormat('MMMM yyyy').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _db.getCategories(),
      _db.getBudgets(_currentMonth),
    ]);
    if (!mounted) return;
    setState(() {
      _categories = results[0] as List<CategoryModel>;
      _budgets = results[1] as List<BudgetModel>;
      _loading = false;
    });
  }

  CategoryModel? _cat(int id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Category actions ──────────────────────────────────────────────────────

  Future<void> _addEditCategory([CategoryModel? cat]) async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => AddEditCategoryScreen(category: cat)),
    );
    if (ok == true) _load();
  }

  Future<void> _deleteCategory(CategoryModel cat) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text(
            'Delete "${cat.name}"?\nExisting transactions may lose their category.'),
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
      await _db.deleteCategory(cat.id!);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Category deleted'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  // ── Budget actions ────────────────────────────────────────────────────────

  Future<void> _showBudgetDialog([BudgetModel? existing]) async {
    final expenseCats = _categories
        .where((c) => c.type == 'expense' || c.type == 'both')
        .toList();
    final amountCtrl = TextEditingController(
        text: existing?.amount.toStringAsFixed(2) ?? '');
    int? selCatId = existing?.categoryId;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(existing != null ? 'Edit Budget' : 'Set Budget'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selCatId,
                decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder()),
                items: expenseCats
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Row(children: [
                            Icon(c.icon, color: c.color, size: 18),
                            const SizedBox(width: 8),
                            Text(c.name),
                          ]),
                        ))
                    .toList(),
                onChanged: (v) => setS(() => selCatId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Monthly Budget (₹)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (selCatId == null) return;
                if ((double.tryParse(amountCtrl.text) ?? 0) <= 0) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && selCatId != null) {
      final amount = double.parse(amountCtrl.text);
      await _db.upsertBudget(BudgetModel(
        id: existing?.id,
        categoryId: selCatId!,
        amount: amount,
        month: _currentMonth,
      ));
      _load();
    }
    amountCtrl.dispose();
  }

  Future<void> _deleteBudget(BudgetModel b) async {
    await _db.deleteBudget(b.id!);
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Budget removed'),
            behavior: SnackBarBehavior.floating),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'Budgets'),
          ],
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tab,
                  children: [
                    _CategoriesTab(
                      categories: _categories,
                      onAdd: () => _addEditCategory(),
                      onEdit: _addEditCategory,
                      onDelete: _deleteCategory,
                    ),
                    _BudgetsTab(
                      budgets: _budgets,
                      month: _monthDisplay,
                      getCat: _cat,
                      onAdd: () => _showBudgetDialog(),
                      onEdit: _showBudgetDialog,
                      onDelete: _deleteBudget,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

// ── Categories tab ────────────────────────────────────────────────────────────

class _CategoriesTab extends StatelessWidget {
  final List<CategoryModel> categories;
  final VoidCallback onAdd;
  final Function(CategoryModel) onEdit;
  final Function(CategoryModel) onDelete;

  const _CategoriesTab({
    required this.categories,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
          itemCount: categories.length,
          itemBuilder: (_, i) {
            final cat = categories[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: cat.color.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: cat.color.withValues(alpha: 0.2), width: 1),
              ),
              child: ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: cat.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(cat.icon, color: cat.color),
                ),
                title: Text(cat.name,
                    style:
                        const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  cat.type[0].toUpperCase() + cat.type.substring(1),
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit(cat);
                    if (v == 'delete') onDelete(cat);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete, size: 18, color: Colors.red),
                        SizedBox(width: 10),
                        Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ]),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'add_category_fab',
            onPressed: onAdd,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

// ── Budgets tab ───────────────────────────────────────────────────────────────

class _BudgetsTab extends StatelessWidget {
  final List<BudgetModel> budgets;
  final String month;
  final CategoryModel? Function(int) getCat;
  final VoidCallback onAdd;
  final Function(BudgetModel) onEdit;
  final Function(BudgetModel) onDelete;

  const _BudgetsTab({
    required this.budgets,
    required this.month,
    required this.getCat,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.15),
                    cs.primary.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month,
                      size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Text('Budgets for $month',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                          fontSize: 13)),
                ],
              ),
            ),
            Expanded(
              child: budgets.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.savings_outlined,
                              size: 56, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No budgets set.',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 15)),
                          SizedBox(height: 4),
                          Text('Tap + to set a monthly budget.',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                      itemCount: budgets.length,
                      itemBuilder: (_, i) {
                        final b = budgets[i];
                        final cat = getCat(b.categoryId);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: cat != null
                                ? Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: cat.color
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(11),
                                    ),
                                    child: Icon(cat.icon,
                                        color: cat.color),
                                  )
                                : const Icon(Icons.category),
                            title: Text(cat?.name ?? 'Unknown',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            subtitle: Text(
                                'Limit: ${fmt.format(b.amount)}',
                                style: const TextStyle(fontSize: 12)),
                            trailing: PopupMenuButton<String>(
                              onSelected: (v) {
                                if (v == 'edit') onEdit(b);
                                if (v == 'delete') onDelete(b);
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(children: [
                                    Icon(Icons.edit, size: 18),
                                    SizedBox(width: 10),
                                    Text('Edit'),
                                  ]),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [
                                    Icon(Icons.delete,
                                        size: 18, color: Colors.red),
                                    SizedBox(width: 10),
                                    Text('Delete',
                                        style: TextStyle(
                                            color: Colors.red)),
                                  ]),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'add_budget_fab',
            onPressed: onAdd,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
