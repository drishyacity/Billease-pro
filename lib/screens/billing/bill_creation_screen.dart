import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/bill_controller.dart';
import '../../controllers/product_controller.dart';
import '../../models/bill_model.dart';
import '../../models/product_model.dart';
import '../products/product_form_screen.dart';
import '../../services/database_service.dart';

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
  bool _isEdit = false;
  String? _editBillId;
  // unified final discount input
  final TextEditingController _finalDiscountCtrl = TextEditingController(text: '0');
  bool _finalDiscountIsPercent = true;
  
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
            icon: Icon(isEstimate ? Icons.print : Icons.save),
            onPressed: isEstimate ? _previewEstimate : _saveBill,
          ),
        ],
      ),
      // Removed FAB per requirement; use Add Product button below
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildCustomerSection(isEstimate),
          ),
          if (widget.billType == BillType.wholesale)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Switch(
                    value: _gstEnabled,
                    onChanged: (v) => setState(() => _gstEnabled = v),
                  ),
                  const Text('GST Bill'),
                  const SizedBox(width: 16),
                  if (_gstEnabled)
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: true, label: Text('Inline GST')),
                        ButtonSegment(value: false, label: Text('Total GST')),
                      ],
                      selected: {_inlineGst},
                      onSelectionChanged: (s) => setState(() => _inlineGst = s.first),
                    ),
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
                        Row(
                          children: [
                            Expanded(child: Text('Qty: ${item.quantity.toStringAsFixed(2)} ${item.unit ?? ''}')),
                            Expanded(child: Text('Price: ₹${item.unitPrice.toStringAsFixed(2)}')),
                          ],
                        ),
                        if (_gstEnabled)
                          Row(
                            children: [
                              Expanded(child: Text('CGST: ${(item.cgst ?? 0).toStringAsFixed(2)}%')),
                              Expanded(child: Text('SGST: ${(item.sgst ?? 0).toStringAsFixed(2)}%')),
                            ],
                          ),
                        Row(
                          children: [
                            Expanded(child: Text('Discount: ${(item.discountPercent ?? 0).toStringAsFixed(2)}%')),
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _showAddItemDialog,
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text('Add Product'),
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.billType != BillType.quickSale) ...[
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
    Product? selectedProduct;
    ProductBatch? selectedBatch;
    String? baseUnit;
    // quantities for all units (base + converted)
    final Map<String, TextEditingController> qtyCtrls = {};
    final priceCtrl = TextEditingController(text: '0'); // per base unit
    final discCtrl = TextEditingController(text: '0');
    final searchCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: const Text('Add Item'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product search
                TextField(
                  controller: searchCtrl,
                  decoration: InputDecoration(
                    labelText: 'Search Product',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Add new product',
                      onPressed: () async {
                        await Get.toNamed('/products/new');
                        // refresh products after returning
                        _productController.loadProducts();
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
                              onTap: () {
                                dialogSetState(() {
                                  selectedProduct = p;
                                  selectedBatch = p.batches.isNotEmpty ? p.batches.first : null;
                                  baseUnit = p.primaryUnit;
                                  qtyCtrls.clear();
                                  if (baseUnit != null) qtyCtrls[baseUnit!] = TextEditingController(text: '0');
                                  for (final uc in p.unitConversions) {
                                    qtyCtrls[uc.convertedUnit] = TextEditingController(text: '0');
                                  }
                                  if (selectedBatch != null) {
                                    if (widget.billType == BillType.wholesale) {
                                      priceCtrl.text = selectedBatch!.sellingPrice.toStringAsFixed(2);
                                    } else {
                                      priceCtrl.text = selectedBatch!.mrp.toStringAsFixed(2);
                                    }
                                  } else {
                                    priceCtrl.text = '0';
                                  }
                                });
                              },
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                // Batch dropdown
                DropdownButtonFormField<ProductBatch>(
                  decoration: const InputDecoration(labelText: 'Batch'),
                  items: (selectedProduct?.batches ?? [])
                      .map((b) => DropdownMenuItem<ProductBatch>(value: b, child: Text('${b.name} • MRP ₹${b.mrp.toStringAsFixed(2)} • Stock ${b.stock}')))
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Unit Price (per base unit)'),
                        ),
                      ),
                    ],
                  ),
                ],
                if (widget.billType == BillType.wholesale) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: discCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Discount % (optional)'),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (selectedProduct == null || selectedBatch == null) return;
                // compute total quantity in base unit from all unit inputs
                double totalBaseQty = 0.0;
                final base = baseUnit ?? selectedProduct!.primaryUnit;
                for (final uc in selectedProduct!.unitConversions) {
                  // factor: how many base units in 1 converted unit
                  final v = double.tryParse(qtyCtrls[uc.convertedUnit]?.text ?? '0') ?? 0;
                  totalBaseQty += v * uc.conversionFactor;
                }
                // include base unit entry
                totalBaseQty += double.tryParse(qtyCtrls[base]?.text ?? '0') ?? 0;
                if (totalBaseQty <= 0) {
                  Get.snackbar('Quantity required', 'Enter quantity for at least one unit');
                  return;
                }
                final price = double.tryParse(priceCtrl.text) ?? 0.0;
                final discount = double.tryParse(discCtrl.text);
                // update parent state so list refreshes
                setState(() {
                  _items.add(BillItem(
                    productId: selectedProduct!.id,
                    productName: selectedProduct!.name,
                    quantity: totalBaseQty,
                    unitPrice: price, // per base unit
                    unit: base,
                    batchId: selectedBatch!.id,
                    cgst: widget.billType == BillType.wholesale && _gstEnabled ? (selectedProduct!.gstPercentage / 2) : null,
                    sgst: widget.billType == BillType.wholesale && _gstEnabled ? (selectedProduct!.gstPercentage / 2) : null,
                    discountPercent: widget.billType == BillType.wholesale ? (discount ?? 0) : null,
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBill() async {
    if (_items.isEmpty) {
      Get.snackbar('Error', 'Please add at least one item');
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
      status: BillStatus.completed,
      notes: '',
    );

    if (_isEdit) {
      await _billController.updateBill(bill);
    } else {
      await _billController.addBill(bill);
    }
    // Deduct stock only for completed bills
    if (bill.status == BillStatus.completed) {
      final db = DatabaseService();
      for (final it in _items) {
        if (it.batchId != null) {
          final delta = -it.quantity.round();
          await db.adjustBatchStock(batchId: it.batchId!, delta: delta);
        }
      }
    }
    Get.back();
  }

  void _previewEstimate() {
    if (_items.isEmpty) {
      Get.snackbar('Error', 'Please add at least one item');
      return;
    }
    Get.back();
    Get.snackbar('Estimate', 'Estimate generated (not saved as bill)', snackPosition: SnackPosition.BOTTOM);
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
      // Total GST computed using weighted average by line amounts
      double weightSum = 0.0;
      double weightedPct = 0.0;
      for (final i in _items) {
        final line = i.unitPrice * i.quantity;
        final pct = ((i.cgst ?? 0) + (i.sgst ?? 0));
        weightSum += line;
        weightedPct += line * pct;
      }
      final avgPct = weightSum == 0 ? 0.0 : (weightedPct / weightSum);
      gst = subtotal * (avgPct / 100.0);
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
      Get.snackbar('Error', 'Please add at least one item');
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
    Get.back();
  }

  void _discardBill() {
    _items.clear();
    setState(() {});
    Get.snackbar('Discarded', 'Bill discarded');
  }
}