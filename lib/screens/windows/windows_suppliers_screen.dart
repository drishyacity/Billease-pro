import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_saver/file_saver.dart';
import 'package:excel/excel.dart' as ex;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:typed_data';
import 'package:billease_pro/controllers/supplier_controller.dart';
import 'package:billease_pro/models/supplier_model.dart';

class WindowsSuppliersScreen extends StatefulWidget {
  const WindowsSuppliersScreen({super.key});

  @override
  State<WindowsSuppliersScreen> createState() => _WindowsSuppliersScreenState();
}

// Shared helpers (duplicate of products/customers screen for Windows UI)
ex.CellValue? _toCellValue(Object? e) {
  if (e == null) return null;
  if (e is num) return ex.DoubleCellValue(e.toDouble());
  return ex.TextCellValue(e.toString());
}

void _showProcessing(BuildContext context, String msg) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(children: [const CircularProgressIndicator(), const SizedBox(width: 12), Expanded(child: Text(msg))]),
    ),
  );
}

void _showSuccess(BuildContext context, String msg) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Success'),
      content: Text(msg),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ),
  );
}

String _supplierCodeFor(Supplier s) {
  final base = s.id.replaceAll(RegExp('[^A-Z0-9]'), '').toUpperCase();
  final tail = base.length >= 6 ? base.substring(base.length - 6) : base.padLeft(6, '0');
  return 'SUP-$tail';
}

Future<void> _exportSuppliersExcel(BuildContext context) async {
  try {
    _showProcessing(context, 'Exporting to Excel...');
    final c = Get.find<SupplierController>();
    final excel = ex.Excel.createExcel();
    const sheetName = 'Suppliers';
    final sheet = excel[sheetName];
    final headers = ['code','name','phone','email','gstin','total_purchase','due','status'];
    sheet.appendRow(headers.map((h) => ex.TextCellValue(h)).toList());
    final list = c.filteredSuppliers.isNotEmpty ? c.filteredSuppliers : c.suppliers;
    for (final x in list) {
      final row = [
        _supplierCodeFor(x), x.name, x.phone, x.email ?? '', x.gstin ?? '', x.totalPurchases, x.dueAmount, x.dueAmount > 0 ? 'Due' : 'OK'
      ];
      sheet.appendRow(row.map<ex.CellValue?>((e) => _toCellValue(e)).toList());
    }
    final bytes = excel.encode()!;
    await FileSaver.instance.saveFile(name: 'suppliers_export', bytes: Uint8List.fromList(bytes), ext: 'xlsx', mimeType: MimeType.microsoftExcel);
    _showSuccess(context, 'Exported to Excel');
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export Excel: $e')));
  } finally {
    Navigator.of(context, rootNavigator: true).maybePop();
  }
}

Future<void> _exportSuppliersPdf(BuildContext context) async {
  try {
    _showProcessing(context, 'Exporting to PDF...');
    final c = Get.find<SupplierController>();
    final pdf = pw.Document();
    final headers = ['Code','Name','Phone','Email','GSTIN','Total Purchase','Due','Status'];
    final list = c.filteredSuppliers.isNotEmpty ? c.filteredSuppliers : c.suppliers;
    final rows = <List<String>>[
      for (final x in list)
        [ _supplierCodeFor(x), x.name, x.phone, x.email ?? '-', x.gstin ?? '-', x.totalPurchases.toStringAsFixed(2), x.dueAmount.toStringAsFixed(2), x.dueAmount > 0 ? 'Due' : 'OK' ]
    ];
    pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4.landscape, build: (_) => [
      pw.Text('Suppliers Export', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 12),
      pw.Table.fromTextArray(headers: headers, data: rows),
    ]));
    final bytes = await pdf.save();
    await FileSaver.instance.saveFile(name: 'suppliers_export', bytes: Uint8List.fromList(bytes), ext: 'pdf', mimeType: MimeType.pdf);
    _showSuccess(context, 'Exported to PDF');
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export PDF: $e')));
  } finally {
    Navigator.of(context, rootNavigator: true).maybePop();
  }
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
  final Set<String> _selectedIds = <String>{};

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
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: () async { await _exportSuppliersExcel(context); }, icon: const Icon(Icons.grid_on), label: const Text('Export Excel')),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: () async { await _exportSuppliersPdf(context); }, icon: const Icon(Icons.picture_as_pdf), label: const Text('Export PDF')),
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
                  rowsPerPage: items.isEmpty ? 1 : (items.length < _rowsPerPage ? items.length : _rowsPerPage),
                  availableRowsPerPage: const [10, 25, 50, 100],
                  onRowsPerPageChanged: (v) => setState(() => _rowsPerPage = v ?? _rowsPerPage),
                  columns: const [
                    DataColumn(label: Text('Select')),
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
                    selectedIds: _selectedIds,
                    onSelectionChanged: (id, sel) => setState(() { if (sel) _selectedIds.add(id); else _selectedIds.remove(id); }),
                    onEdit: (s) => _addOrEditSupplier(existing: s),
                    onDelete: (s) async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete Supplier'),
                          content: Text('Are you sure you want to delete ${s.name}?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await controller.deleteSupplier(s.id);
                      }
                    },
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Text('Selected: ${_selectedIds.length}'),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _selectedIds.isEmpty ? null : () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Delete Selected'),
                    content: Text('Delete ${_selectedIds.length} selected suppliers?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (ok == true) {
                  for (final id in _selectedIds.toList()) {
                    await controller.deleteSupplier(id);
                  }
                  setState(() => _selectedIds.clear());
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Selected'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: () async { await _exportSuppliersExcel(context); }, icon: const Icon(Icons.grid_on), label: const Text('Export Excel')),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: () async { await _exportSuppliersPdf(context); }, icon: const Icon(Icons.picture_as_pdf), label: const Text('Export PDF')),
            const Spacer(),
            Obx(() => Text('Total: ${controller.filteredSuppliers.length}')),
          ]),
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
  final Set<String> selectedIds;
  final void Function(String id, bool sel) onSelectionChanged;
  final void Function(Supplier s) onEdit;
  final void Function(Supplier s) onDelete;
  _SuppliersSource({required this.items, required this.selectedIds, required this.onSelectionChanged, required this.onEdit, required this.onDelete});

  @override
  DataRow? getRow(int index) {
    if (index >= items.length) return null;
    final s = items[index];
    return DataRow.byIndex(
      index: index,
      selected: selectedIds.contains(s.id),
      onSelectChanged: (sel) {
        if (sel == null) return;
        onSelectionChanged(s.id, sel);
        notifyListeners();
      },
      cells: [
        DataCell(Checkbox(value: selectedIds.contains(s.id), onChanged: (v) => onSelectionChanged(s.id, v ?? false))),
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
          IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Delete', onPressed: () => onDelete(s)),
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
