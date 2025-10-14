import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/bill_controller.dart';
import '../../controllers/product_controller.dart';
import '../../models/bill_model.dart';
import '../../models/product_model.dart';

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
  final List<BillItem> _items = [];
  bool _gstEnabled = false; // only for wholesale
  bool _inlineGst = true; // inline vs total GST
  double _finalDiscountPercent = 0.0;
  double _finalDiscountAmount = 0.0;
  double _extraAmount = 0.0;
  final TextEditingController _extraAmountName = TextEditingController(text: 'Charges');
  
  @override
  Widget build(BuildContext context) {
    final isEstimate = (Get.arguments is Map && (Get.arguments['estimate'] == true));
    return Scaffold(
      appBar: AppBar(
        title: Text(isEstimate ? 'New Estimate' : 'New ${widget.billType.toString().split('.').last} Bill'),
        actions: [
          IconButton(
            icon: Icon(isEstimate ? Icons.print : Icons.save),
            onPressed: isEstimate ? _previewEstimate : _saveBill,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _customerNameController,
              decoration: InputDecoration(
                labelText: isEstimate ? 'Customer Name (optional)' : 'Customer Name',
                border: const OutlineInputBorder(),
              ),
            ),
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
                ElevatedButton(
                  onPressed: _addItem,
                  child: const Text('Add Item'),
                ),
                const SizedBox(height: 12),
                if (widget.billType != BillType.quickSale) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Final Discount %'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() => _finalDiscountPercent = double.tryParse(v) ?? 0),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Final Discount Amount'),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => setState(() => _finalDiscountAmount = double.tryParse(v) ?? 0),
                        ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    _showAddItemDialog();
  }

  void _showAddItemDialog() {
    Product? selectedProduct;
    ProductBatch? selectedBatch;
    String? selectedUnit;
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController(text: '0');
    final discCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Item'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Product dropdown
                DropdownButtonFormField<Product>(
                  decoration: const InputDecoration(labelText: 'Product'),
                  items: _productController.products
                      .map((p) => DropdownMenuItem<Product>(value: p, child: Text(p.name)))
                      .toList(),
                  onChanged: (p) {
                    setState(() {
                      selectedProduct = p;
                      selectedBatch = p?.batches.isNotEmpty == true ? p!.batches.first : null;
                      selectedUnit = p?.primaryUnit;
                      priceCtrl.text = selectedBatch?.sellingPrice.toStringAsFixed(2) ?? '0';
                    });
                  },
                  value: selectedProduct,
                ),
                const SizedBox(height: 12),
                // Batch dropdown
                DropdownButtonFormField<ProductBatch>(
                  decoration: const InputDecoration(labelText: 'Batch'),
                  items: (selectedProduct?.batches ?? [])
                      .map((b) => DropdownMenuItem<ProductBatch>(value: b, child: Text('${b.name} • MRP ₹${b.mrp.toStringAsFixed(2)} • Stock ${b.stock}')))
                      .toList(),
                  onChanged: (b) {
                    setState(() {
                      selectedBatch = b;
                      priceCtrl.text = (b?.sellingPrice ?? 0).toStringAsFixed(2);
                    });
                  },
                  value: selectedBatch,
                ),
                const SizedBox(height: 12),
                // Unit dropdown from primary + conversions
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Unit'),
                  items: [
                    if (selectedProduct != null) selectedProduct!.primaryUnit,
                    ...((selectedProduct?.unitConversions ?? []).map((u) => u.convertedUnit)),
                  ].whereType<String>().map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (u) => setState(() => selectedUnit = u),
                  value: selectedUnit,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Quantity'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Unit Price'),
                      ),
                    ),
                  ],
                ),
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
                final qty = double.tryParse(qtyCtrl.text) ?? 1.0;
                final price = double.tryParse(priceCtrl.text) ?? 0.0;
                final discount = double.tryParse(discCtrl.text);
                setState(() {
                  _items.add(BillItem(
                    productId: selectedProduct!.id,
                    productName: selectedProduct!.name,
                    quantity: qty,
                    unitPrice: price,
                    unit: selectedUnit ?? selectedProduct!.primaryUnit,
                    batchId: selectedBatch!.id,
                    cgst: widget.billType == BillType.wholesale && _gstEnabled ? 9 : null,
                    sgst: widget.billType == BillType.wholesale && _gstEnabled ? 9 : null,
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

  void _saveBill() {
    if (_items.isEmpty) {
      Get.snackbar('Error', 'Please add at least one item');
      return;
    }

    final totals = _computeTotals();
    final bill = Bill(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      type: widget.billType,
      customerName: _customerNameController.text.isEmpty ? 'Guest' : _customerNameController.text,
      items: _items,
      totalAmount: totals['grand']!,
      status: BillStatus.draft,
      notes: '',
    );

    _billController.addBill(bill);
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
      // GST on subtotal after line discounts are not applied in total GST mode
      final totalGstPercent = _items.isEmpty ? 0.0 : _items.map((i) => ((i.cgst ?? 0) + (i.sgst ?? 0))).reduce((a, b) => a + b) / _items.length;
      gst = subtotal * (totalGstPercent / 100.0);
    }

    double finalDiscPctAmount = 0.0;
    if (_finalDiscountPercent > 0) {
      finalDiscPctAmount = (subtotal + gst) * (_finalDiscountPercent / 100.0);
    }

    double grand = subtotal + gst - finalDiscPctAmount - _finalDiscountAmount + _extraAmount;
    return {
      'subtotal': subtotal,
      'gst': gst,
      'finalDiscPct': finalDiscPctAmount,
      'grand': grand,
    };
  }
}