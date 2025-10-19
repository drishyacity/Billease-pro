import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:billease_pro/controllers/product_controller.dart';
import 'package:billease_pro/controllers/customer_controller.dart';
import 'package:billease_pro/controllers/bill_controller.dart';
import 'package:billease_pro/models/bill_model.dart';
import 'package:billease_pro/models/product_model.dart';

class RemoveSelectedIntent extends Intent {
  const RemoveSelectedIntent();
}

class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

class WindowsBillingScreen extends StatefulWidget {
  const WindowsBillingScreen({super.key});

  @override
  State<WindowsBillingScreen> createState() => _WindowsBillingScreenState();
}

class _WindowsBillingScreenState extends State<WindowsBillingScreen> {
  final ProductController productController = Get.find<ProductController>();
  final CustomerController customerController = Get.find<CustomerController>();
  final BillController billController = Get.find<BillController>();

  // Header form fields
  String _invoiceType = 'sales'; // sales/purchase/estimate/return (UI only for now)
  DateTime _invoiceDate = DateTime.now();
  String _paymentMode = 'cash';
  DateTime? _dueDate;
  final TextEditingController _refCtrl = TextEditingController();

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _customerCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  String? _customerId;
  bool _gstEnabled = false;
  bool _inlineGst = true;
  final TextEditingController _finalDiscountCtrl = TextEditingController(text: '0');
  bool _finalDiscountIsPercent = true;
  final TextEditingController _extraAmountName = TextEditingController(text: 'Charges');
  double _extraAmount = 0.0;

  final List<BillItem> _items = [];
  int? _selectedIndex;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _customerCtrl.dispose();
    _searchFocus.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  void _addProduct(Product p) {
    final batch = p.batches.isNotEmpty ? p.batches.first : null;
    final price = batch?.sellingPrice ?? 0.0;
    setState(() {
      _items.add(BillItem(
        productId: p.id,
        productName: p.name,
        quantity: 1,
        unitPrice: price,
        batchId: batch?.id,
        unit: p.primaryUnit,
      ));
      _selectedIndex = _items.length - 1;
    });
  }

  void _removeSelected() {
    if (_selectedIndex == null) return;
    setState(() {
      _items.removeAt(_selectedIndex!);
      _selectedIndex = null;
    });
  }

  double _computeSubtotal() {
    double sum = 0;
    for (final it in _items) {
      sum += it.quantity * it.unitPrice;
    }
    return sum;
  }

  double _computeFinalDiscountOn(double subtotal) {
    final v = double.tryParse(_finalDiscountCtrl.text.trim()) ?? 0;
    return _finalDiscountIsPercent ? subtotal * v / 100 : v;
  }

  double _computeTotalGstOn(double subtotalAfterDisc) {
    if (!_gstEnabled || _inlineGst) return 0.0;
    // simple total-GST slider not implemented here; assume percent via extraAmountName? Keep 0 for now.
    return 0.0;
  }

  double _computeGrandTotal() {
    final subtotal = _computeSubtotal();
    final disc = _computeFinalDiscountOn(subtotal);
    final afterDisc = (subtotal - disc).clamp(0.0, double.infinity) as double;
    final gst = _computeTotalGstOn(afterDisc);
    return afterDisc + gst + _extraAmount;
  }

  Future<void> _saveBill({bool draft = false}) async {
    if (_items.isEmpty) {
      Get.snackbar('Add items', 'Please add at least one product', snackPosition: SnackPosition.TOP);
      return;
    }
    final total = _computeGrandTotal();
    final bill = Bill(
      type: BillType.retail,
      customerId: _customerId,
      customerName: _customerCtrl.text.isNotEmpty ? _customerCtrl.text : null,
      items: _items,
      totalAmount: total,
      status: draft ? BillStatus.draft : BillStatus.completed,
      finalDiscountValue: double.tryParse(_finalDiscountCtrl.text) ?? 0,
      finalDiscountIsPercent: _finalDiscountIsPercent,
      extraAmount: _extraAmount,
      extraAmountName: _extraAmountName.text,
      gstEnabled: _gstEnabled,
      inlineGst: _inlineGst,
    );
    await billController.addBill(bill);
    setState(() {
      _items.clear();
      _customerCtrl.clear();
      _customerId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.f2): ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.f5): ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.f9): ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.delete): RemoveSelectedIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF): FocusSearchIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) { _saveBill(draft: false); return null; }),
          RemoveSelectedIntent: CallbackAction<RemoveSelectedIntent>(onInvoke: (_) { _removeSelected(); return null; }),
          FocusSearchIntent: CallbackAction<FocusSearchIntent>(onInvoke: (_) { _searchFocus.requestFocus(); return null; }),
        },
        child: DefaultTabController(
          length: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Invoice Type
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<String>(
                        value: _invoiceType,
                        items: const [
                          DropdownMenuItem(value: 'sales', child: Text('Sales Invoice')),
                          DropdownMenuItem(value: 'estimate', child: Text('Estimate')),
                          DropdownMenuItem(value: 'return', child: Text('Sales Return')),
                        ],
                        onChanged: (v) => setState(() => _invoiceType = v ?? 'sales'),
                        decoration: InputDecoration(labelText: 'Invoice Type'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _finalDiscountCtrl,
                        decoration: const InputDecoration(labelText: 'Final Discount'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(children: [
                      Checkbox(
                        value: _finalDiscountIsPercent,
                        onChanged: (v) => setState(() => _finalDiscountIsPercent = v ?? true),
                      ),
                      const Text('As %'),
                    ]),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: 220,
                      child: TextField(
                        controller: _extraAmountName,
                        decoration: const InputDecoration(labelText: 'Extra Amount Name'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 160,
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Extra Amount'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => setState(() => _extraAmount = double.tryParse(v) ?? 0),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Subtotal: ₹${_computeSubtotal().toStringAsFixed(2)}'),
                        Text('Grand: ₹${_computeGrandTotal().toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
