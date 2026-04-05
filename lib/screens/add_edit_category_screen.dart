import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/category_model.dart';

class AddEditCategoryScreen extends StatefulWidget {
  final CategoryModel? category;

  const AddEditCategoryScreen({super.key, this.category});

  @override
  State<AddEditCategoryScreen> createState() =>
      _AddEditCategoryScreenState();
}

class _AddEditCategoryScreenState extends State<AddEditCategoryScreen> {
  final _db = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();

  String _type = 'expense';
  int _iconCode = Icons.category.codePoint;
  int _colorValue = 0xFF2196F3;

  static const _icons = [
    Icons.restaurant, Icons.directions_car, Icons.shopping_bag,
    Icons.receipt_long, Icons.movie, Icons.local_hospital,
    Icons.school, Icons.local_grocery_store, Icons.work,
    Icons.laptop, Icons.trending_up, Icons.card_giftcard,
    Icons.fitness_center, Icons.flight, Icons.home,
    Icons.pets, Icons.sports_soccer, Icons.music_note,
    Icons.coffee, Icons.local_bar, Icons.category,
  ];

  static const _colors = [
    0xFFF44336, 0xFFE91E63, 0xFF9C27B0, 0xFF3F51B5,
    0xFF2196F3, 0xFF00BCD4, 0xFF009688, 0xFF4CAF50,
    0xFF8BC34A, 0xFFCDDC39, 0xFFFFC107, 0xFFFF9800,
    0xFFFF5722, 0xFF795548, 0xFF9E9E9E, 0xFF607D8B,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      final c = widget.category!;
      _nameCtrl.text = c.name;
      _type = c.type;
      _iconCode = c.iconCode;
      _colorValue = c.colorValue;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final cat = CategoryModel(
      id: widget.category?.id,
      name: _nameCtrl.text.trim(),
      iconCode: _iconCode,
      colorValue: _colorValue,
      type: _type,
    );
    if (widget.category != null) {
      await _db.updateCategory(cat);
    } else {
      await _db.insertCategory(cat);
    }
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selColor = Color(_colorValue);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        title: Text(
            widget.category != null ? 'Edit Category' : 'Add Category'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: selColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: selColor, width: 2),
                  ),
                  child: Icon(
                    IconData(_iconCode, fontFamily: 'MaterialIcons'),
                    color: selColor,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  prefixIcon: Icon(Icons.label),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    v?.trim().isEmpty == true ? 'Name required' : null,
              ),
              const SizedBox(height: 16),

              // Type
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'expense', label: Text('Expense')),
                  ButtonSegment(value: 'income', label: Text('Income')),
                  ButtonSegment(value: 'both', label: Text('Both')),
                ],
                selected: {_type},
                onSelectionChanged: (v) =>
                    setState(() => _type = v.first),
              ),
              const SizedBox(height: 24),

              // Icon picker
              const Text('Choose Icon',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _icons.map((icon) {
                  final sel = _iconCode == icon.codePoint;
                  return InkWell(
                    onTap: () =>
                        setState(() => _iconCode = icon.codePoint),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: sel
                            ? selColor.withValues(alpha: 0.2)
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: sel
                            ? Border.all(color: selColor, width: 2)
                            : null,
                      ),
                      child: Icon(icon,
                          color: sel ? selColor : Colors.grey[600]),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Color picker
              const Text('Choose Color',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _colors.map((cv) {
                  final c = Color(cv);
                  final sel = _colorValue == cv;
                  return GestureDetector(
                    onTap: () => setState(() => _colorValue = cv),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: sel ? 44 : 38,
                      height: sel ? 44 : 38,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: sel
                            ? Border.all(color: Colors.black54, width: 3)
                            : null,
                        boxShadow: sel
                            ? [
                                BoxShadow(
                                    color: c.withValues(alpha: 0.5),
                                    blurRadius: 8)
                              ]
                            : null,
                      ),
                      child: sel
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: Icon(
                      widget.category != null ? Icons.save : Icons.add),
                  label: Text(widget.category != null
                      ? 'Update Category'
                      : 'Add Category'),
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
