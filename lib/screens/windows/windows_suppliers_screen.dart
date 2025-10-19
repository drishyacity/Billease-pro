import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:billease_pro/controllers/supplier_controller.dart';
import 'package:billease_pro/models/supplier_model.dart';

class WindowsSuppliersScreen extends StatefulWidget {
  const WindowsSuppliersScreen({super.key});

  @override
  State<WindowsSuppliersScreen> createState() => _WindowsSuppliersScreenState();
}

class _WindowsSuppliersScreenState extends State<WindowsSuppliersScreen> {
  late final SupplierController controller;
  
  @override
  void initState() {
    super.initState();
    try {
      controller = Get.find<SupplierController>();
    } catch (_) {
      controller = Get.put(SupplierController());
    }
  }
  final TextEditingController _searchCtrl = TextEditingController();
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Suppliers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by name, phone, email, code'),
                  onChanged: (v) => setState(() => controller.filter(v)),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _addOrEditSupplier(),
                icon: const Icon(Icons.add),
                label: const Text('Add Supplier'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              final items = controller.filteredSuppliers;
              return Card(
                clipBehavior: Clip.antiAlias,
                child: PaginatedDataTable(
                  header: const Text('Suppliers'),
                  rowsPerPage: _rowsPerPage,
                  availableRowsPerPage: const [10, 25, 50, 100],
                  onRowsPerPageChanged: (v) => setState(() => _rowsPerPage = v ?? _rowsPerPage),
                  columns: const [
                    DataColumn(label: Text('Supplier Code')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('GSTIN')),
                    DataColumn(label: Text('Total Purchase')),
                    DataColumn(label: Text('Due')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  source: _SuppliersSource(
                    items: items,
                    onEdit: (s) => _addOrEditSupplier(existing: s),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _codeFor(Supplier s) {
    final base = s.id.replaceAll(RegExp('[^A-Z0-9]'), '').toUpperCase();
    final tail = base.length >= 6 ? base.substring(base.length - 6) : base.padLeft(6, '0');
    return 'SUP-$tail';
  }

  Future<void> _addOrEditSupplier({Supplier? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final addressCtrl = TextEditingController(text: existing?.address ?? '');
    final gstinCtrl = TextEditingController(text: existing?.gstin ?? '');

    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add Supplier' : 'Edit Supplier'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')), 
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')), 
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address')), 
              TextField(controller: gstinCtrl, decoration: const InputDecoration(labelText: 'GSTIN')), 
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (res != true) return;

    final now = DateTime.now();
    final supplier = Supplier(
      id: existing?.id ?? 'SUP_${now.microsecondsSinceEpoch}',
      name: nameCtrl.text.trim(),
      phone: phoneCtrl.text.trim(),
      email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
      address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
      gstin: gstinCtrl.text.trim().isEmpty ? null : gstinCtrl.text.trim(),
      totalPurchases: existing?.totalPurchases ?? 0.0,
      dueAmount: existing?.dueAmount ?? 0.0,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    if (existing == null) {
      await controller.addSupplier(supplier);
    } else {
      await controller.updateSupplier(supplier);
    }
  }
}

class _SuppliersSource extends DataTableSource {
  final List<Supplier> items;
  final void Function(Supplier s) onEdit;
  _SuppliersSource({required this.items, required this.onEdit});

  @override
  DataRow? getRow(int index) {
    if (index >= items.length) return null;
    final s = items[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(_codeFor(s))),
        DataCell(Text(s.name)),
        DataCell(Text(s.phone)),
        DataCell(Text(s.email ?? '-')),
        DataCell(Text(s.gstin ?? '-')),
        DataCell(Text('₹${s.totalPurchases.toStringAsFixed(2)}')),
        DataCell(Text('₹${s.dueAmount.toStringAsFixed(2)}')),
        DataCell(Text(s.dueAmount > 0 ? 'Due' : 'OK')),
        DataCell(Row(children: [
          IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit', onPressed: () => onEdit(s)),
        ])),
      ],
    );
  }

  String _codeFor(Supplier s) {
    final base = s.id.replaceAll(RegExp('[^A-Z0-9]'), '').toUpperCase();
    final tail = base.length >= 6 ? base.substring(base.length - 6) : base.padLeft(6, '0');
    return 'SUP-$tail';
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => items.length;

  @override
  int get selectedRowCount => 0;
}
