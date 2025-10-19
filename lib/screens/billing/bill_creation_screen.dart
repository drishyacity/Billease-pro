import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/bill_controller.dart';
import '../../controllers/product_controller.dart';
import '../../models/bill_model.dart';
import '../../models/product_model.dart';
import '../products/product_form_screen.dart';
import 'billing_screen.dart';
import '../../services/database_service.dart';
import 'package:sqflite/sqflite.dart';

class BillCreationScreen extends StatefulWidget {
  final BillType billType;
  
  const BillCreationScreen({Key? key, required this.billType}) : super(key: key);

  @override
  State<BillCreationScreen> createState() => _BillCreationScreenState();
}

class _BillCreationScreenState extends State<BillCreationScreen> {
  final BillController _billController = Get.find();
  final ProductController _productController = Get.find();
  final TextEditingController _customerNameController = TextEditingController();
  String? _customerId; // for retail/wholesale
  final List<BillItem> _items = [];
  bool _gstEnabled = false; // only for wholesale
  bool _inlineGst = true; // inline vs total GST
  double _finalDiscountPercent = 0.0;
  double _finalDiscountAmount = 0.0; // deprecated by unified input below
  double _extraAmount = 0.0;
  final TextEditingController _extraAmountName = TextEditingController(text: 'Charges');
  // User-entered Total GST % for wholesale total-GST mode
  final TextEditingController _totalGstCtrl = TextEditingController(text: '0');
  bool _isEdit = false;
  String? _editBillId;
  // unified final discount input
  final TextEditingController _finalDiscountCtrl = TextEditingController(text: '0');
  bool _finalDiscountIsPercent = true;
  bool _isSaving = false;
  
  Future<String> _generateBillId({required bool isEstimate}) async {
    final now = DateTime.now();
    String dd = now.day.toString().padLeft(2, '0');
    String mm = now.month.toString().padLeft(2, '0');
    String yy = (now.year % 100).toString().padLeft(2, '0');
    final prefix = isEstimate
        ? 'RE'
        : (widget.billType == BillType.quickSale
            ? 'QB'
            : widget.billType == BillType.retail
                ? 'RB'
                : 'WB');
    final prefixDate = '$prefix$dd$mm$yy';
    // Count existing bills today for this prefix
    final db = await DatabaseService().database;
    final res = await db.rawQuery('SELECT COUNT(*) AS c FROM bills WHERE id LIKE ?', ['${prefixDate}%']);
    final count = (res.first['c'] as int?) ?? 0;
    final seq = (count + 1).toString();
    return '$prefixDate$seq';
  }

  void _previewBill() {
    if (_items.isEmpty) {
      Get.snackbar('Error', 'Please add at least one item', snackPosition: SnackPosition.TOP);
      return;
    }
    final totals = _computeTotals();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bill Preview'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: ${_customerNameController.text.isEmpty ? 'Customer' : _customerNameController.text}'),
                const SizedBox(height: 8),
                const Divider(),
                ..._items.map((i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(i.productName, overflow: TextOverflow.ellipsis)),
                          Text('${i.quantity.toStringAsFixed(2)} x ${i.unitPrice.toStringAsFixed(2)}'),
                          Text('₹${_computeLineTotal(i).toStringAsFixed(2)}'),
                        ],
                      ),
                    )),
                const Divider(),
                Text('Subtotal: ₹${totals['subtotal']!.toStringAsFixed(2)}'),
                if (widget.billType == BillType.wholesale && _gstEnabled && !_inlineGst)
                  Text('GST (${_totalGstCtrl.text.trim()}%): ₹${totals['gst']!.toStringAsFixed(2)}'),
                if (_extraAmount > 0) Text('${_extraAmountName.text}: +₹${_extraAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 8),
                Text('Grand Total: ₹${totals['grand']!.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _refreshGstForItems() {
    // Recalculate per-line CGST/SGST and discount eligibility based on current mode
    if (widget.billType != BillType.wholesale) {
      for (var i = 0; i < _items.length; i++) {
        final it = _items[i];
        _items[i] = BillItem(
          id: it.id,
          productId: it.productId,
          productName: it.productName,
          quantity: it.quantity,
          unitPrice: it.unitPrice,
          totalPrice: it.quantity * it.unitPrice,
          batchId: it.batchId,
          unit: it.unit,
          cgst: null,
          sgst: null,
          discountPercent: null,
          mrpOverride: it.mrpOverride,
          expiryOverride: it.expiryOverride,
        );
      }
      return;
    }
    for (var i = 0; i < _items.length; i++) {
      final it = _items[i];
      double? cgstVal;
      double? sgstVal;
      double? discVal;
      if (_gstEnabled) {
        // find product
        final prod = _productController.products.firstWhereOrNull((p) => p.id == it.productId);
        if (prod != null) {
          cgstVal = prod.cgstPercentage;
          sgstVal = prod.sgstPercentage;
          if ((cgstVal == 0 || cgstVal == null) && (sgstVal == 0 || sgstVal == null) && prod.gstPercentage > 0) {
            cgstVal = prod.gstPercentage / 2;
            sgstVal = prod.gstPercentage / 2;
          }
          if (_inlineGst) {
            discVal = it.discountPercent ?? (prod.discountPercentage);
          } else {
            discVal = null; // total GST mode: no inline discount
          }
        }
      }
      _items[i] = BillItem(
        id: it.id,
        productId: it.productId,
        productName: it.productName,
        quantity: it.quantity,
        unitPrice: it.unitPrice,
        totalPrice: it.quantity * it.unitPrice,
        batchId: it.batchId,
        unit: it.unit,
        cgst: _gstEnabled ? cgstVal : null,
        sgst: _gstEnabled ? sgstVal : null,
        discountPercent: (_gstEnabled && _inlineGst) ? discVal : null,
        mrpOverride: it.mrpOverride,
        expiryOverride: it.expiryOverride,
      );
    }
  }
  
  @override
  void initState() {
    super.initState();
    // Prefill for edit mode
    if (Get.arguments is Map && Get.arguments['editBill'] is Bill) {
      final Bill eb = Get.arguments['editBill'];
      _isEdit = true;
      _editBillId = eb.id;
      _customerId = eb.customerId;
      _customerNameController.text = eb.customerName ?? '';
      _items.addAll(eb.items);
      if (widget.billType == BillType.wholesale) {
        // If any item had GST, enable
        _gstEnabled = eb.items.any((i) => (i.cgst ?? 0) > 0 || (i.sgst ?? 0) > 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEstimate = (Get.arguments is Map && (Get.arguments['estimate'] == true));
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEstimate
              ? (_isEdit ? 'Edit Estimate' : 'New Estimate')
              : (_isEdit ? 'Edit ${widget.billType.toString().split('.').last} Bill' : 'New ${widget.billType.toString().split('.').last} Bill'),
        ),
        actions: [
          IconButton(
            tooltip: 'Preview',
            icon: const Icon(Icons.visibility_outlined),
            onPressed: _previewBill,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildCustomerSection(isEstimate),
          ),
          // Add Product button directly under customer box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _showAddItemDialog,
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Add Product'),
              ),
            ),
          ),
          if (widget.billType == BillType.wholesale)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: _gstEnabled,
                            onChanged: (v) => setState(() {
                              _gstEnabled = v;
                              _refreshGstForItems();
                            }),
                          ),
                          const Text('GST Bill'),
                        ],
                      ),
                      if (_gstEnabled)
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(value: true, label: Text('Inline GST')),
                            ButtonSegment(value: false, label: Text('Total GST')),
                          ],
                          selected: {_inlineGst},
                          onSelectionChanged: (s) => setState(() {
                            _inlineGst = s.first;
                            _refreshGstForItems();
                          }),
                        ),
                    ],
                  ),
                  if (_gstEnabled && !_inlineGst) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _totalGstCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Total GST %'),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        // Inline editable quantity and unit price
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: item.quantity.toStringAsFixed(2),
                                decoration: InputDecoration(labelText: 'Qty (${item.unit ?? ''})'),
                                keyboardType: TextInputType.number,
                                onFieldSubmitted: (v) {
                                  final q = double.tryParse(v) ?? item.quantity;
                                  setState(() {
                                    _items[index] = BillItem(
                                      id: item.id,
                                      productId: item.productId,
                                      productName: item.productName,
                                      quantity: q,
                                      unitPrice: item.unitPrice,
                                      totalPrice: q * item.unitPrice,
                                      batchId: item.batchId,
                                      unit: item.unit,
                                      cgst: item.cgst,
                                      sgst: item.sgst,
                                      discountPercent: item.discountPercent,
                                    );
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: item.unitPrice.toStringAsFixed(2),
                                decoration: const InputDecoration(labelText: 'Unit Price'),
                                keyboardType: TextInputType.number,
                                onFieldSubmitted: (v) {
                                  final p = double.tryParse(v) ?? item.unitPrice;
                                  setState(() {
                                    _items[index] = BillItem(
                                      id: item.id,
                                      productId: item.productId,
                                      productName: item.productName,
                                      quantity: item.quantity,
                                      unitPrice: p,
                                      totalPrice: item.quantity * p,
                                      batchId: item.batchId,
                                      unit: item.unit,
                                      cgst: item.cgst,
                                      sgst: item.sgst,
                                      discountPercent: item.discountPercent,
                                    );
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        // Inline editable MRP and Expiry (per-bill overrides)
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: (item.mrpOverride ?? 0).toStringAsFixed(2),
                                decoration: const InputDecoration(labelText: 'MRP (override)'),
                                keyboardType: TextInputType.number,
                                onFieldSubmitted: (v) {
                                  final mrp = double.tryParse(v);
                                  setState(() {
                                    _items[index] = BillItem(
                                      id: item.id,
                                      productId: item.productId,
                                      productName: item.productName,
                                      quantity: item.quantity,
                                      unitPrice: item.unitPrice,
                                      totalPrice: item.quantity * item.unitPrice,
                                      batchId: item.batchId,
                                      unit: item.unit,
                                      cgst: item.cgst,
                                      sgst: item.sgst,
                                      discountPercent: item.discountPercent,
                                      mrpOverride: mrp,
                                      expiryOverride: item.expiryOverride,
                                    );
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: item.expiryOverride ?? DateTime.now().add(const Duration(days: 365)),
                                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _items[index] = BillItem(
                                        id: item.id,
                                        productId: item.productId,
                                        productName: item.productName,
                                        quantity: item.quantity,
                                        unitPrice: item.unitPrice,
                                        totalPrice: item.quantity * item.unitPrice,
                                        batchId: item.batchId,
                                        unit: item.unit,
                                        cgst: item.cgst,
                                        sgst: item.sgst,
                                        discountPercent: item.discountPercent,
                                        mrpOverride: item.mrpOverride,
                                        expiryOverride: picked,
                                      );
                                    });
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(labelText: 'Expiry (override)'),
                                  child: Text(
                                    item.expiryOverride == null
                                        ? 'Not set'
                                        : '${item.expiryOverride!.day}/${item.expiryOverride!.month}/${item.expiryOverride!.year}',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_gstEnabled && _inlineGst)
                          Row(
                            children: [
                              Expanded(child: Text('CGST: ${(item.cgst ?? 0).toStringAsFixed(2)}%')),
                              Expanded(child: Text('SGST: ${(item.sgst ?? 0).toStringAsFixed(2)}%')),
                            ],
                          ),
                        if (widget.billType == BillType.wholesale && _gstEnabled && _inlineGst)
                          Row(
                            children: [
                              Expanded(child: Text('Discount: ${(item.discountPercent ?? 0).toStringAsFixed(2)}%')),
                              Expanded(child: Text('Line Total: ₹${_computeLineTotal(item).toStringAsFixed(2)}')),
                            ],
                          )
                        else
                          Row(
                            children: [
                              const Expanded(child: SizedBox()),
                              Expanded(child: Text('Line Total: ₹${_computeLineTotal(item).toStringAsFixed(2)}')),
                            ],
                          ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => setState(() => _items.removeAt(index)),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remove'),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isEstimate && widget.billType != BillType.quickSale) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _finalDiscountCtrl,
                          decoration: const InputDecoration(labelText: 'Final Discount'),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Checkbox(
                            value: _finalDiscountIsPercent,
                            onChanged: (v) => setState(() => _finalDiscountIsPercent = v ?? true),
                          ),
                          const Text('As %'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _extraAmountName,
                          decoration: const InputDecoration(labelText: 'Extra Amount Name'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Extra Amount'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() => _extraAmount = double.tryParse(v) ?? 0),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                _buildTotals(),
                const SizedBox(height: 12),
                if (isEstimate)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _discardBill,
                          child: const Text('Discard'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveEstimate,
                          child: const Text('Save Estimate'),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _discardBill,
                          child: const Text('Discard'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saveDraft,
                          child: const Text('Save as Draft'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveBill,
                          child: const Text('Save Bill'),
                        ),
                      ),
                    ],
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addItem() { _showAddItemDialog(); }

  void _showAddItemDialog() {
    // Open instantly; rely on already loaded products. Refresh happens elsewhere if needed.
    Product? selectedProduct;
    ProductBatch? selectedBatch;
    String? baseUnit;
    // quantities for all units (base + converted)
    final Map<String, TextEditingController> qtyCtrls = {};
    // local map of unit -> factor (how many base units in 1 of this unit)
    final Map<String, double> unitFactors = {};
    final priceCtrl = TextEditingController(text: '0'); // per base unit
    final discCtrl = TextEditingController(text: '0');
    final searchCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => WillPopScope(
          onWillPop: () async {
            final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
            if (isKeyboardOpen) {
              FocusScope.of(context).unfocus();
              return false; // consume back to just hide keyboard
            }
            return true; // allow dialog to close
          },
          child: Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Add Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    // Product search
                    TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        labelText: 'Search Product',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          tooltip: 'Add new product',
                          onPressed: () async {
                            await Get.to(() => ProductFormScreen(product: null));
                            await _productController.loadProducts();
                            dialogSetState(() {});
                          },
                        ),
                      ),
                      onChanged: (_) => dialogSetState(() {}),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 150,
                      child: ListView(
                        children: _productController.products
                            .where((p) => p.name.toLowerCase().contains(searchCtrl.text.toLowerCase()))
                            .map((p) => ListTile(
                                  title: Text(p.name),
                                  subtitle: Text(p.barcode ?? ''),
                                  selected: selectedProduct?.id == p.id,
                                  trailing: selectedProduct?.id == p.id
                                      ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
                                      : null,
                                  onTap: () {
                                    dialogSetState(() {
                                      selectedProduct = p;
                                      selectedBatch = p.batches.isNotEmpty ? p.batches.first : null;
                                      baseUnit = p.primaryUnit;
                                      qtyCtrls.clear();
                                      unitFactors.clear();
                                      if (baseUnit != null) {
                                        qtyCtrls[baseUnit!] = TextEditingController(text: '0');
                                        unitFactors[baseUnit!] = 1.0;
                                      }
                                      for (final uc in p.unitConversions) {
                                        qtyCtrls[uc.convertedUnit] = TextEditingController(text: '0');
                                        unitFactors[uc.convertedUnit] = uc.conversionFactor;
                                      }
                                      if (selectedBatch != null) {
                                        final isEstimate = (Get.arguments is Map && (Get.arguments['estimate'] == true));
                                        if (widget.billType == BillType.wholesale || isEstimate) {
                                          priceCtrl.text = selectedBatch!.sellingPrice.toStringAsFixed(2);
                                        } else {
                                          priceCtrl.text = selectedBatch!.mrp.toStringAsFixed(2);
                                        }
                                      } else {
                                        priceCtrl.text = '0';
                                      }
                                      // Prefill discount for wholesale inline GST from product defaults
                                      if (widget.billType == BillType.wholesale && _gstEnabled && _inlineGst) {
                                        discCtrl.text = selectedProduct!.discountPercentage.toStringAsFixed(2);
                                      }
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ),
                    if (selectedProduct != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(selectedProduct!.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            if (selectedBatch != null)
                              Text('Batch: ${selectedBatch!.name} • MRP ₹${selectedBatch!.mrp.toStringAsFixed(2)} • Stock ${selectedBatch!.stock}',
                                  style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                    // Add new unit for selected product
                    if (selectedProduct != null) Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async {
                          final unitCtrl = TextEditingController();
                          final factorCtrl = TextEditingController();
                          bool largerThanBase = true;
                          final base = selectedProduct!.primaryUnit;
                          final res = await showDialog<UnitConversion>(
                            context: context,
                            builder: (context) => StatefulBuilder(
                              builder: (context, setS) => AlertDialog(
                                title: const Text('Create Unit'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(controller: unitCtrl, decoration: const InputDecoration(labelText: 'Unit name')),
                                      const SizedBox(height: 8),
                                      Row(children: [
                                        const Text('Unit larger than base'),
                                        const SizedBox(width: 8),
                                        Switch(value: largerThanBase, onChanged: (v){ setS(()=> largerThanBase = v); }),
                                      ]),
                                      TextField(
                                        controller: factorCtrl,
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          labelText: largerThanBase
                                            ? 'How many $base in 1 <unit>?' : 'How many <unit> in 1 $base?'),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Cancel')),
                                  ElevatedButton(
                                    onPressed: () {
                                      final name = unitCtrl.text.trim();
                                      final val = double.tryParse(factorCtrl.text.trim());
                                      if (name.isNotEmpty && val != null && val > 0) {
                                        final factor = largerThanBase ? val : (1/val);
                                        Navigator.pop(context, UnitConversion(baseUnit: base, convertedUnit: name, conversionFactor: factor));
                                      }
                                    },
                                    child: const Text('Add'),
                                  )
                                ],
                              ),
                            ),
                          );
                          if (res != null) {
                            // persist into DB and update controller and local unit map
                            final db = DatabaseService();
                            final dbi = await db.database;
                            await dbi.insert('unit_conversions', {
                              'product_id': selectedProduct!.id,
                              'base_unit': res.baseUnit,
                              'converted_unit': res.convertedUnit,
                              'conversion_factor': res.conversionFactor,
                            }, conflictAlgorithm: ConflictAlgorithm.replace);
                            await _productController.loadProducts();
                            dialogSetState(() {
                              qtyCtrls[res.convertedUnit] = TextEditingController(text: '0');
                              unitFactors[res.convertedUnit] = res.conversionFactor;
                            });
                          }
                        },
                        icon: const Icon(Icons.straighten),
                        label: const Text('Create New Unit'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Batch dropdown
                    DropdownButtonFormField<ProductBatch>(
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Batch'),
                      items: (selectedProduct?.batches ?? [])
                          .map((b) => DropdownMenuItem<ProductBatch>(
                                value: b,
                                child: Text(
                                  '${b.name} • MRP ₹${b.mrp.toStringAsFixed(2)} • Stock ${b.stock}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                          .toList(),
                      onChanged: (b) {
                        dialogSetState(() {
                          selectedBatch = b;
                          if (b != null) {
                            if (widget.billType == BillType.wholesale) {
                              priceCtrl.text = b.sellingPrice.toStringAsFixed(2);
                            } else {
                              priceCtrl.text = b.mrp.toStringAsFixed(2);
                            }
                          }
                        });
                      },
                      value: selectedBatch,
                    ),
                    const SizedBox(height: 12),
                    // Quantities for all units
                    if (selectedProduct != null) ...[
                      ...qtyCtrls.entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: TextField(
                              controller: e.value,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(labelText: 'Quantity (${e.key})'),
                            ),
                          )),
                      TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Unit Price (per base unit)'),
                      ),
                    ],
                    if (widget.billType == BillType.wholesale && _gstEnabled && _inlineGst) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: discCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Discount % (optional)'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (selectedProduct == null || selectedBatch == null) return;
                            // compute total quantity in base unit from all unit inputs (using local unitFactors)
                            double totalBaseQty = 0.0;
                            final base = baseUnit ?? selectedProduct!.primaryUnit;
                            // ensure base unit factor present
                            unitFactors[base] = unitFactors[base] ?? 1.0;
                            for (final entry in unitFactors.entries) {
                              final unit = entry.key;
                              final factor = entry.value;
                              final v = double.tryParse(qtyCtrls[unit]?.text ?? '0') ?? 0;
                              totalBaseQty += v * factor;
                            }
                            if (totalBaseQty <= 0) {
                              Get.snackbar('Quantity required', 'Enter quantity for at least one unit', snackPosition: SnackPosition.TOP);
                              return;
                            }
                            final price = double.tryParse(priceCtrl.text) ?? 0.0;
                            final discount = double.tryParse(discCtrl.text);
                            // Determine CGST/SGST for inline GST
                            double? cgstVal;
                            double? sgstVal;
                            if (widget.billType == BillType.wholesale && _gstEnabled) {
                              cgstVal = selectedProduct!.cgstPercentage;
                              sgstVal = selectedProduct!.sgstPercentage;
                              if ((cgstVal == 0 || cgstVal == null) && (sgstVal == 0 || sgstVal == null) && selectedProduct!.gstPercentage > 0) {
                                cgstVal = selectedProduct!.gstPercentage / 2;
                                sgstVal = selectedProduct!.gstPercentage / 2;
                              }
                            }
                            setState(() {
                              _items.add(BillItem(
                                productId: selectedProduct!.id,
                                productName: selectedProduct!.name,
                                quantity: totalBaseQty,
                                unitPrice: price, // per base unit
                                unit: base,
                                batchId: selectedBatch!.id,
                                cgst: (widget.billType == BillType.wholesale && _gstEnabled) ? cgstVal : null,
                                sgst: (widget.billType == BillType.wholesale && _gstEnabled) ? sgstVal : null,
                                discountPercent: (widget.billType == BillType.wholesale && _gstEnabled && _inlineGst) ? (discount ?? 0) : null,
                                // Initialize per-bill overrides from chosen batch
                                mrpOverride: selectedBatch?.mrp,
                                expiryOverride: selectedBatch?.expiryDate,
                              ));
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveBill() async {
    if (_items.isEmpty) {
      Get.snackbar('Error', 'Please add at least one item', snackPosition: SnackPosition.TOP);
      return;
    }
    if (_isSaving) return; // prevent double tap
    setState(() { _isSaving = true; });

    final totals = _computeTotals();
    final billId = _isEdit ? _editBillId! : await _generateBillId(isEstimate: false);
    final bill = Bill(
      id: billId,
      date: DateTime.now(),
      type: widget.billType,
      customerId: _customerId,
      customerName: widget.billType == BillType.quickSale
          ? 'Guest'
          : (_customerNameController.text.isEmpty ? 'Customer' : _customerNameController.text),
      items: _items,
      totalAmount: totals['grand']!,
      status: BillStatus.completed,
      notes: '',
      finalDiscountValue: double.tryParse(_finalDiscountCtrl.text) ?? 0.0,
      finalDiscountIsPercent: _finalDiscountIsPercent,
      extraAmount: _extraAmount,
      extraAmountName: _extraAmountName.text.trim().isEmpty ? null : _extraAmountName.text.trim(),
      gstEnabled: widget.billType == BillType.wholesale ? _gstEnabled : false,
      inlineGst: _inlineGst,
    );

    if (_isEdit) {
      await _billController.updateBill(bill);
    } else {
      await _billController.addBill(bill);
    }
    await _billController.loadBills();
    setState(() { _isSaving = false; });
    Get.offAll(() => const BillingScreen());
  }

  void _previewEstimate() {
    if (_items.isEmpty) {
      Get.snackbar('Error', 'Please add at least one item', snackPosition: SnackPosition.TOP);
      return;
    }
    Get.back();
    Get.snackbar('Estimate', 'Estimate generated (not saved as bill)', snackPosition: SnackPosition.TOP);
  }

  Future<void> _saveEstimate() async {
    if (_items.isEmpty) {
      Get.snackbar('Error', 'Please add at least one item', snackPosition: SnackPosition.TOP);
      return;
    }
    if (_isSaving) return;
    setState(() { _isSaving = true; });
    final totals = _computeTotals();
    final estId = _isEdit ? _editBillId! : await _generateBillId(isEstimate: true);
    final bill = Bill(
      id: estId,
      date: DateTime.now(),
      type: widget.billType, // retail UI pricing, but notes marks this as estimate
      customerId: _customerId,
      customerName: (_customerNameController.text.isEmpty ? 'Customer' : _customerNameController.text),
      items: _items,
      totalAmount: totals['grand']!,
      status: BillStatus.draft,
      notes: 'estimate',
      finalDiscountValue: double.tryParse(_finalDiscountCtrl.text) ?? 0.0,
      finalDiscountIsPercent: _finalDiscountIsPercent,
      extraAmount: _extraAmount,
      extraAmountName: _extraAmountName.text.trim().isEmpty ? null : _extraAmountName.text.trim(),
      gstEnabled: widget.billType == BillType.wholesale ? _gstEnabled : false,
      inlineGst: _inlineGst,
    );
    if (_isEdit) {
      await _billController.updateBill(bill);
    } else {
      await _billController.addBill(bill);
    }
    await _billController.loadBills();
    setState(() { _isSaving = false; });
    Get.offAll(() => const BillingScreen());
  }

  double _computeLineTotal(BillItem item) {
    double base = item.unitPrice * item.quantity;
    if (widget.billType == BillType.wholesale && _gstEnabled && _inlineGst) {
      final disc = (item.discountPercent ?? 0) / 100.0;
      base = base * (1 - disc);
      final gst = ((item.cgst ?? 0) + (item.sgst ?? 0)) / 100.0;
      base = base * (1 + gst);
    }
    return base;
  }

  Widget _buildTotals() {
    final totals = _computeTotals();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Subtotal: ₹${totals['subtotal']!.toStringAsFixed(2)}'),
        if (widget.billType == BillType.wholesale && _gstEnabled && !_inlineGst)
          Text('GST: ₹${totals['gst']!.toStringAsFixed(2)}'),
        if (_finalDiscountPercent > 0)
          Text('Final Discount (${_finalDiscountPercent.toStringAsFixed(2)}%): -₹${totals['finalDiscPct']!.toStringAsFixed(2)}'),
        if (_finalDiscountAmount > 0)
          Text('Final Discount (Amount): -₹${_finalDiscountAmount.toStringAsFixed(2)}'),
        if (_extraAmount > 0)
          Text('${_extraAmountName.text}: +₹${_extraAmount.toStringAsFixed(2)}'),
        const Divider(),
        Text(
          'Grand Total: ₹${totals['grand']!.toStringAsFixed(2)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Map<String, double> _computeTotals() {
    double subtotal;
    if (widget.billType == BillType.wholesale && _gstEnabled && _inlineGst) {
      subtotal = _items.fold(0.0, (sum, i) => sum + _computeLineTotal(i));
    } else {
      subtotal = _items.fold(0.0, (sum, i) => sum + (i.unitPrice * i.quantity));
    }

    double gst = 0.0;
    if (widget.billType == BillType.wholesale && _gstEnabled && !_inlineGst) {
      // Use user-entered total GST %
      final pct = double.tryParse(_totalGstCtrl.text.trim()) ?? 0.0;
      gst = subtotal * (pct / 100.0);
    }

    // unified final discount
    final discVal = double.tryParse(_finalDiscountCtrl.text) ?? 0.0;
    final double finalDiscAmount = _finalDiscountIsPercent ? ((subtotal + gst) * (discVal / 100.0)) : discVal;
    double grand = subtotal + gst - finalDiscAmount + _extraAmount;
    return {
      'subtotal': subtotal,
      'gst': gst,
      'finalDiscPct': _finalDiscountIsPercent ? finalDiscAmount : 0.0,
      'grand': grand,
    };
  }

  // Customer section for retail/wholesale
  Widget _buildCustomerSection(bool isEstimate) {
    if (widget.billType == BillType.quickSale) {
      return TextField(
        controller: _customerNameController,
        decoration: const InputDecoration(
          labelText: 'Customer (optional)',
          border: OutlineInputBorder(),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customerNameController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _pickCustomer,
              child: const Text('Select'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _addCustomer,
              child: const Text('New Customer'),
            )
          ],
        ),
      ],
    );
  }

  Future<void> _pickCustomer() async {
    final db = DatabaseService();
    final rows = await db.getAllCustomers();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Customer'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, i) {
              final r = rows[i];
              return ListTile(
                title: Text(r['name'] ?? ''),
                subtitle: Text(r['phone'] ?? ''),
                onTap: () {
                  setState(() {
                    _customerId = r['id'];
                    _customerNameController.text = r['name'] ?? '';
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _addCustomer() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Customer'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) return;
              final id = DateTime.now().millisecondsSinceEpoch.toString();
              await DatabaseService().upsertCustomer({
                'id': id,
                'name': nameCtrl.text.trim(),
                'phone': phoneCtrl.text.trim(),
                'email': emailCtrl.text.trim(),
                'address': addrCtrl.text.trim(),
                'gstin': null,
                'totalPurchases': 0,
                'dueAmount': 0,
                'createdAt': DateTime.now().toIso8601String(),
                'updatedAt': DateTime.now().toIso8601String(),
              });
              setState(() {
                _customerId = id;
                _customerNameController.text = nameCtrl.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDraft() async {
    if (_items.isEmpty) {
      Get.snackbar('Error', 'Please add at least one item', snackPosition: SnackPosition.TOP);
      return;
    }
    final totals = _computeTotals();
    final bill = Bill(
      id: _isEdit ? _editBillId : DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      type: widget.billType,
      customerId: _customerId,
      customerName: widget.billType == BillType.quickSale
          ? 'Guest'
          : (_customerNameController.text.isEmpty ? 'Customer' : _customerNameController.text),
      items: _items,
      totalAmount: totals['grand']!,
      status: BillStatus.draft,
      notes: 'draft',
    );
    if (_isEdit) {
      await _billController.updateBill(bill);
    } else {
      await _billController.addBill(bill);
    }
    await _billController.loadBills();
    Get.snackbar('Saved as Draft', 'Draft saved successfully', snackPosition: SnackPosition.TOP);
    await Future.delayed(const Duration(milliseconds: 500));
    Get.back();
  }

  void _discardBill() {
    _items.clear();
    setState(() {});
    Get.snackbar('Discarded', 'Bill discarded', snackPosition: SnackPosition.TOP);
    Future.delayed(const Duration(milliseconds: 300), () {
      Get.offAll(() => const BillingScreen());
    });
  }
}