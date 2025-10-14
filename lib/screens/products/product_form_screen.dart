import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';
import '../../models/product_model.dart';
import '../../services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;
  const ProductFormScreen({super.key, required this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _barcode = TextEditingController();
  final _category = TextEditingController();
  final _mrp = TextEditingController(text: '0');
  final _sellingPrice = TextEditingController(text: '0');
  final _costPrice = TextEditingController(text: '0');
  final _stock = TextEditingController(text: '0');
  DateTime? _expiryDate;
  final _primaryUnitCtrl = TextEditingController(text: 'piece');
  final List<UnitConversion> _conversions = [];
  double _gst = 0.0;
  int _lowStockAlert = 10;
  int _expiryAlertDays = 30;
  final List<Map<String, dynamic>> _formBatches = [];

  final _productController = Get.find<ProductController>();

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _name.text = p.name;
      _barcode.text = p.barcode ?? '';
      _category.text = p.category ?? '';
      _primaryUnitCtrl.text = p.primaryUnit;
      _gst = p.gstPercentage;
      _lowStockAlert = p.lowStockAlert;
      _expiryAlertDays = p.expiryAlertDays;
      if (p.batches.isNotEmpty) {
        _mrp.text = p.batches.first.mrp.toString();
        _sellingPrice.text = p.batches.first.sellingPrice.toString();
        _costPrice.text = p.batches.first.costPrice.toString();
        _stock.text = p.batches.first.stock.toString();
        _expiryDate = p.batches.first.expiryDate;
        _formBatches.clear();
        for (final b in p.batches) {
          _formBatches.add({
            'id': b.id,
            'name': b.name,
            'cost_price': b.costPrice,
            'selling_price': b.sellingPrice,
            'mrp': b.mrp,
            'expiry_date': b.expiryDate,
            'stock': b.stock,
          });
        }
      }
    }
  }

  Widget _buildUnitConversionsCard() {
    final baseUnit = _primaryUnitCtrl.text.trim().isEmpty ? 'piece' : _primaryUnitCtrl.text.trim();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Unit Conversions', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () async {
                    final conv = await _showAddConversionDialog(baseUnit);
                    if (conv != null) {
                      setState(() => _conversions.add(conv));
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_conversions.isEmpty)
              const Text('No conversions. Example: 1 box = 12 piece')
            else
              Column(
                children: _conversions.asMap().entries.map((e) {
                  final idx = e.key;
                  final uc = e.value;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('1 ${uc.convertedUnit} = ${uc.conversionFactor} ${uc.baseUnit}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => setState(() => _conversions.removeAt(idx)),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Future<UnitConversion?> _showAddConversionDialog(String baseUnit) async {
    final convertedCtrl = TextEditingController();
    final factorCtrl = TextEditingController();
    bool largerThanBase = true;
    final res = await showDialog<UnitConversion>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Unit Conversion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: convertedCtrl,
                decoration: const InputDecoration(labelText: 'Converted Unit (e.g., box)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Unit is larger than base'),
                  const SizedBox(width: 8),
                  StatefulBuilder(
                    builder: (context, setState) => Switch(
                      value: largerThanBase,
                      onChanged: (v) => setState(() => largerThanBase = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: factorCtrl,
                decoration: InputDecoration(
                    labelText: largerThanBase
                        ? 'How many $baseUnit in 1 <unit>?'
                        : 'How many <unit> in 1 $baseUnit?'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final name = convertedCtrl.text.trim();
                final val = double.tryParse(factorCtrl.text.trim());
                if (name.isNotEmpty && val != null && val > 0) {
                  final factor = largerThanBase ? val : (1 / val);
                  Navigator.pop(context, UnitConversion(baseUnit: baseUnit, convertedUnit: name, conversionFactor: factor));
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    return res;
  }

  Widget _buildBatchesFormCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Batches', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () async {
                    final name = TextEditingController(text: 'Batch ${_formBatches.length + 1}');
                    final cp = TextEditingController();
                    final sp = TextEditingController();
                    final mrp = TextEditingController();
                    final stock = TextEditingController();
                    DateTime? expiry;
                    await showDialog(
                      context: context,
                      builder: (context) => StatefulBuilder(
                        builder: (context, setState) => AlertDialog(
                          title: const Text('Add Batch'),
                          content: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(controller: name, decoration: const InputDecoration(labelText: 'Batch Name')),
                                TextField(controller: cp, decoration: const InputDecoration(labelText: 'Cost Price'), keyboardType: TextInputType.number),
                                TextField(controller: sp, decoration: const InputDecoration(labelText: 'Selling Price'), keyboardType: TextInputType.number),
                                TextField(controller: mrp, decoration: const InputDecoration(labelText: 'MRP'), keyboardType: TextInputType.number),
                                TextField(controller: stock, decoration: const InputDecoration(labelText: 'Opening Stock'), keyboardType: TextInputType.number),
                                const SizedBox(height: 12),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now().add(const Duration(days: 365)),
                                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                                    );
                                    if (picked != null) setState(() => expiry = picked);
                                  },
                                  child: InputDecorator(
                                    decoration: const InputDecoration(labelText: 'Expiry Date (optional)'),
                                    child: Text(expiry == null ? 'Not set' : '${expiry!.day}/${expiry!.month}/${expiry!.year}'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {});
                                Navigator.pop(context);
                                this.setState(() {
                                  _formBatches.add({
                                    'name': name.text.trim().isEmpty ? 'Batch' : name.text.trim(),
                                    'cost_price': double.tryParse(cp.text) ?? 0.0,
                                    'selling_price': double.tryParse(sp.text) ?? 0.0,
                                    'mrp': double.tryParse(mrp.text) ?? 0.0,
                                    'expiry_date': expiry,
                                    'stock': int.tryParse(stock.text) ?? 0,
                                  });
                                });
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Batch'),
                ),
              ],
            ),
            if (_formBatches.isEmpty)
              const Text('No batches added. The default batch will be created if none are added.')
            else
              Column(
                children: _formBatches.asMap().entries.map((e) {
                  final idx = e.key;
                  final b = e.value;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(b['name']?.toString() ?? 'Batch'),
                    subtitle: Text('Stock: ${b['stock'] ?? 0}, SP: ₹${(b['selling_price'] as num?)?.toDouble().toString() ?? '0'}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => setState(() => _formBatches.removeAt(idx)),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _barcode.dispose();
    _category.dispose();
    _primaryUnitCtrl.dispose();
    _mrp.dispose();
    _sellingPrice.dispose();
    _costPrice.dispose();
    _stock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Product' : 'Add Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Product Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barcode,
                decoration: const InputDecoration(labelText: 'Barcode/SKU'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _primaryUnitCtrl,
                      decoration: const InputDecoration(labelText: 'Primary Unit (e.g., piece, box)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final unitCtrl = TextEditingController();
                      final factorCtrl = TextEditingController();
                      final baseUnit = _primaryUnitCtrl.text.trim().isEmpty ? 'piece' : _primaryUnitCtrl.text.trim();
                      bool largerThanBase = true;
                      final res = await showDialog<UnitConversion>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Add New Unit'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit name (e.g., box)')),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Text('Unit is larger than base'),
                                  const SizedBox(width: 8),
                                  StatefulBuilder(
                                    builder: (context, setState) => Switch(
                                      value: largerThanBase,
                                      onChanged: (v) => setState(() => largerThanBase = v),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: factorCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: largerThanBase
                                      ? 'How many $baseUnit in 1 <unit>?'
                                      : 'How many <unit> in 1 $baseUnit?',
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                            ElevatedButton(
                              onPressed: () {
                                final name = unitCtrl.text.trim();
                                final val = double.tryParse(factorCtrl.text.trim());
                                if (name.isNotEmpty && val != null && val > 0) {
                                  final factor = largerThanBase ? val : (1 / val);
                                  Navigator.pop(context, UnitConversion(baseUnit: baseUnit, convertedUnit: name, conversionFactor: factor));
                                }
                              },
                              child: const Text('Add'),
                            ),
                          ],
                        ),
                      );
                      if (res != null) {
                        final exists = _conversions.any((uc) => uc.convertedUnit.toLowerCase() == res.convertedUnit.toLowerCase());
                        if (!exists) {
                          setState(() => _conversions.add(res));
                        } else {
                          Get.snackbar('Duplicate', 'Unit already added', snackPosition: SnackPosition.BOTTOM);
                        }
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New Unit'),
                  )
                ],
              ),
              const SizedBox(height: 12),
              _buildUnitConversionsCard(),
              const SizedBox(height: 12),
              _buildBatchesFormCard(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _mrp,
                      decoration: const InputDecoration(labelText: 'MRP'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sellingPrice,
                      decoration: const InputDecoration(labelText: 'Selling Price'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costPrice,
                      decoration: const InputDecoration(labelText: 'Cost Price'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stock,
                      decoration: const InputDecoration(labelText: 'Opening Stock'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 3650)),
                        );
                        if (picked != null) {
                          setState(() => _expiryDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Expiry Date (batch)'),
                        child: Text(
                          _expiryDate == null ? 'Not set' : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _gst.toString(),
                      decoration: const InputDecoration(labelText: 'GST %'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _gst = double.tryParse(v) ?? 0.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: _lowStockAlert.toString(),
                      decoration: const InputDecoration(labelText: 'Low Stock Alert'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _lowStockAlert = int.tryParse(v) ?? 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _expiryAlertDays.toString(),
                decoration: const InputDecoration(labelText: 'Expiry Alert Days'),
                keyboardType: TextInputType.number,
                onChanged: (v) => _expiryAlertDays = int.tryParse(v) ?? 30,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(isEdit ? 'Save Changes' : 'Add Product'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final db = DatabaseService();
    final id = widget.product?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();
    await db.insertProduct({
      'id': id,
      'name': _name.text.trim(),
      'barcode': _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
      'category': _category.text.trim().isEmpty ? null : _category.text.trim(),
      'primary_unit': _primaryUnitCtrl.text.trim().isEmpty ? 'piece' : _primaryUnitCtrl.text.trim(),
      'gst_percentage': _gst,
      'low_stock_alert': _lowStockAlert,
      'expiry_alert_days': _expiryAlertDays,
      'created_at': (widget.product?.createdAt ?? now).toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    // Persist unit conversions
    for (final uc in _conversions) {
      await db.database.then((dbi) async {
        await dbi.insert('unit_conversions', {
          'product_id': id,
          'base_unit': uc.baseUnit,
          'converted_unit': uc.convertedUnit,
          'conversion_factor': uc.conversionFactor,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      });
    }

    if (_formBatches.isNotEmpty) {
      for (final b in _formBatches) {
        await db.insertBatch({
          'id': b['id'] ?? 'BATCH_${id}_${DateTime.now().microsecondsSinceEpoch}',
          'product_id': id,
          'name': b['name'] ?? 'Batch',
          'cost_price': (b['cost_price'] as num?)?.toDouble() ?? 0.0,
          'selling_price': (b['selling_price'] as num?)?.toDouble() ?? 0.0,
          'mrp': (b['mrp'] as num?)?.toDouble() ?? 0.0,
          'expiry_date': (b['expiry_date'] as DateTime?)?.toIso8601String(),
          'stock': (b['stock'] as int?) ?? 0,
        });
      }
    } else {
      await db.insertBatch({
        'id': 'BATCH_${id}_1',
        'product_id': id,
        'name': 'Default',
        'cost_price': double.tryParse(_costPrice.text) ?? 0.0,
        'selling_price': double.tryParse(_sellingPrice.text) ?? 0.0,
        'mrp': double.tryParse(_mrp.text) ?? 0.0,
        'expiry_date': _expiryDate?.toIso8601String(),
        'stock': int.tryParse(_stock.text) ?? 0,
      });
    }

    _productController.loadProducts();
    Get.back();
    Get.snackbar(
      'Success',
      widget.product == null ? 'Product added' : 'Product updated',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}


