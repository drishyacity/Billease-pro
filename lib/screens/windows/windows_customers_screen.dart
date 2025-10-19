import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:billease_pro/controllers/customer_controller.dart';
import 'package:billease_pro/controllers/bill_controller.dart';
import 'package:billease_pro/models/customer_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:typed_data';
import 'package:excel/excel.dart' as ex;

class WindowsCustomersScreen extends StatefulWidget {
  const WindowsCustomersScreen({super.key});

  @override
  State<WindowsCustomersScreen> createState() => _WindowsCustomersScreenState();
}

// Shared helpers (duplicate of products screen for Windows UI)
ex.CellValue? _toCellValue(Object? e) {
  if (e == null) return null;
  if (e is num) return ex.DoubleCellValue(e.toDouble());
  return ex.TextCellValue(e.toString());
}

void _showProcessing(BuildContext context, String msg) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) { return AlertDialog(
      content: Row(children: [const CircularProgressIndicator(), const SizedBox(width: 12), Expanded(child: Text(msg))]),
    ); },
  );
}

void _showSuccess(BuildContext context, String msg) {
  showDialog(
    context: context,
    builder: (_) { return AlertDialog(
      title: const Text('Success'),
      content: Text(msg),
      actions: [TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('OK'))],
    ); },
  );
}

class _WindowsCustomersScreenState extends State<WindowsCustomersScreen> {
  final CustomerController controller = Get.find<CustomerController>();
  final BillController billController = Get.find<BillController>();
  final TextEditingController _searchCtrl = TextEditingController();
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  final Set<String> _selectedIds = <String>{};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _addOrEditCustomer({Customer? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final addrCtrl = TextEditingController(text: existing?.address ?? '');
    final gstCtrl = TextEditingController(text: existing?.gstin ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) { return AlertDialog(
        title: Text(existing == null ? 'Add Customer' : 'Edit Customer'),
        content: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 8),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
              const SizedBox(height: 8),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 8),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address')),
              const SizedBox(height: 8),
              TextField(controller: gstCtrl, decoration: const InputDecoration(labelText: 'GSTIN')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context, false); }, child: const Text('Cancel')),
          ElevatedButton(onPressed: () { Navigator.pop(context, true); }, child: const Text('Save')),
        ],
      ); },
    );
    if (result == true) {
      if (existing == null) {
        final now = DateTime.now();
        final c = Customer(
          id: const Uuid().v4(),
          name: nameCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
          address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
          gstin: gstCtrl.text.trim().isEmpty ? null : gstCtrl.text.trim(),
          createdAt: now,
          updatedAt: now,
        );
        await controller.addCustomer(c);
      } else {
        final now = DateTime.now();
        final c = Customer(
          id: existing.id,
          name: nameCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
          address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
          gstin: gstCtrl.text.trim().isEmpty ? null : gstCtrl.text.trim(),
          totalPurchases: existing.totalPurchases,
          dueAmount: existing.dueAmount,
          createdAt: existing.createdAt,
          updatedAt: now,
        );
        await controller.updateCustomer(c);
      }
      setState(() {});
    }
  }

  DateTime? _lastPurchaseFor(String customerId) {
    final bills = billController.bills.where((b) => b.customerId == customerId);
    if (bills.isEmpty) return null;
    return bills.map((b) => b.date).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  void _launchTel(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Customers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search customers'),
                  onChanged: (v) {
                    setState(() {
                      controller.filterCustomers(v);
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: () { _addOrEditCustomer(); }, icon: const Icon(Icons.person_add), label: const Text('Add')),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: () async { await _exportCustomersExcel(context); }, icon: const Icon(Icons.grid_on), label: const Text('Export Excel')),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: () async { await _exportCustomersPdf(context); }, icon: const Icon(Icons.picture_as_pdf), label: const Text('Export PDF')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              final items = controller.filteredCustomers.isNotEmpty || _searchCtrl.text.isNotEmpty
                  ? controller.filteredCustomers
                  : controller.customers;
              if (items.isEmpty) {
                return const Center(child: Text('No customers'));
              }
              return Card(
                clipBehavior: Clip.antiAlias,
                child: PaginatedDataTable(
                  header: const Text('Customers'),
                  rowsPerPage: (items.length < _rowsPerPage ? items.length : _rowsPerPage),
                  availableRowsPerPage: const [10, 25, 50, 100],
                  onRowsPerPageChanged: (v) {
                    setState(() {
                      _rowsPerPage = v ?? _rowsPerPage;
                    });
                  },
                  columns: const [
                    DataColumn(label: Text('Select')),
                    DataColumn(label: Text('Customer Code')),
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('GSTIN')),
                    DataColumn(label: Text('Total Sale')),
                    DataColumn(label: Text('Due')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Last Purchase')),
                    DataColumn(label: Text('Actions')),
                  ],
                  source: _CustomersSource(
                    items: items,
                    lastPurchaseFor: _lastPurchaseFor,
                    onEdit: (c) => _addOrEditCustomer(existing: c),
                    onCall: (p) { _launchTel(p); },
                    onEmail: (e) { _launchEmail(e); },
                    selectedIds: _selectedIds,
                    onSelectionChanged: (id, sel) {
                      setState(() {
                        if (sel) {
                          _selectedIds.add(id);
                        } else {
                          _selectedIds.remove(id);
                        }
                      });
                    },
                    onDelete: (c) async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) { return AlertDialog(
                          title: const Text('Delete Customer'),
                          content: Text('Are you sure you want to delete ${c.name}?'),
                          actions: [
                            TextButton(onPressed: () { Navigator.pop(context, false); }, child: const Text('Cancel')),
                            FilledButton(onPressed: () { Navigator.pop(context, true); }, child: const Text('Delete')),
                          ],
                        ); },
                      );
                      if (ok == true) {
                        controller.deleteCustomer(c.id);
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
                  builder: (_) { return AlertDialog(
                    title: const Text('Delete Selected'),
                    content: Text('Delete ${_selectedIds.length} selected customers?'),
                    actions: [
                      TextButton(onPressed: () { Navigator.pop(context, false); }, child: const Text('Cancel')),
                      FilledButton(onPressed: () { Navigator.pop(context, true); }, child: const Text('Delete')),
                    ],
                  ); },
                );
                if (ok == true) {
                  for (final id in _selectedIds.toList()) {
                    await controller.deleteCustomer(id);
                  }
                  setState(() {
                    _selectedIds.clear();
                  });
                }
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete Selected'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: () async { await _exportCustomersExcel(context); }, icon: const Icon(Icons.grid_on), label: const Text('Export Excel')),
            const SizedBox(width: 8),
            OutlinedButton.icon(onPressed: () async { await _exportCustomersPdf(context); }, icon: const Icon(Icons.picture_as_pdf), label: const Text('Export PDF')),
            const Spacer(),
            Text('Total: ${controller.filteredCustomers.isNotEmpty || _searchCtrl.text.isNotEmpty ? controller.filteredCustomers.length : controller.customers.length}')
          ]),
        ],
      ),
    );
  }
}

class _CustomersSource extends DataTableSource {
  final List<Customer> items;
  final DateTime? Function(String customerId) lastPurchaseFor;
  final void Function(Customer c) onEdit;
  final void Function(String phone) onCall;
  final void Function(String email) onEmail;
  final Set<String> selectedIds;
  final void Function(String id, bool sel) onSelectionChanged;
  final void Function(Customer c) onDelete;

  _CustomersSource({
    required this.items,
    required this.lastPurchaseFor,
    required this.onEdit,
    required this.onCall,
    required this.onEmail,
    required this.selectedIds,
    required this.onSelectionChanged,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= items.length) return null;
    final c = items[index];
    final last = lastPurchaseFor(c.id);
    return DataRow.byIndex(
      index: index,
      selected: selectedIds.contains(c.id),
      onSelectChanged: (sel) {
        if (sel == null) return;
        onSelectionChanged(c.id, sel);
        notifyListeners();
      },
      cells: [
        DataCell(Checkbox(value: selectedIds.contains(c.id), onChanged: (v) { onSelectionChanged(c.id, v ?? false); })),
        DataCell(Text(_codeFor(c))),
        DataCell(Text(c.name)),
        DataCell(Row(children: [Text(c.phone), const SizedBox(width: 8), IconButton(icon: const Icon(Icons.call), tooltip: 'Call', onPressed: () { onCall(c.phone); })])),
        DataCell(Row(children: [
          Text(c.email ?? '-'),
          (c.email ?? '').isNotEmpty
              ? Row(children: [const SizedBox(width: 8), IconButton(icon: const Icon(Icons.email_outlined), tooltip: 'Email', onPressed: () { onEmail(c.email!); })])
              : const SizedBox.shrink(),
        ])),
        DataCell(Text(c.gstin ?? '-')),
        DataCell(Text('₹${c.totalPurchases.toStringAsFixed(2)}')),
        DataCell(Text('₹${c.dueAmount.toStringAsFixed(2)}')),
        DataCell(Text(_statusFor(c))),
        DataCell(Text(last == null ? '-' : '${last.day}/${last.month}/${last.year}')),
        DataCell(Row(children: [
          IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit', onPressed: () { onEdit(c); }),
          IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Delete', onPressed: () { onDelete(c); }),
        ])),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => items.length;

  @override
  int get selectedRowCount => 0;

  String _codeFor(Customer c) {
    // Auto-generated code from id, display-only
    final base = c.id.replaceAll(RegExp('[^A-Z0-9]'), '').toUpperCase();
    final tail = base.length >= 6 ? base.substring(base.length - 6) : base.padLeft(6, '0');
    return 'CUST-$tail';
  }

  String _statusFor(Customer c) {
    if (c.dueAmount > 0) return 'Due';
    return 'OK';
  }
}

Future<void> _exportCustomersExcel(BuildContext context) async {
  try {
    _showProcessing(context, 'Exporting to Excel...');
    final c = Get.find<CustomerController>();
    final excel = ex.Excel.createExcel();
    const sheetName = 'Customers';
    if (excel.sheets.keys.contains('Sheet1')) {
      excel.rename('Sheet1', sheetName);
    }
    excel.setDefaultSheet(sheetName);
    final sheet = excel[sheetName];
    final headers = ['code','name','phone','email','gstin','total_sale','due','status'];
    sheet.appendRow(headers.map((h) => ex.TextCellValue(h)).toList());
    final list = c.filteredCustomers.isNotEmpty ? c.filteredCustomers : c.customers;
    for (final x in list) {
      final row = [
        _codeForStatic(x), x.name, x.phone, x.email ?? '', x.gstin ?? '', x.totalPurchases, x.dueAmount, x.dueAmount > 0 ? 'Due' : 'OK'
      ];
      sheet.appendRow(row.map<ex.CellValue?>((e) => _toCellValue(e)).toList());
    }
    final bytes = excel.encode()!;
    await FileSaver.instance.saveFile(name: 'customers_export', bytes: Uint8List.fromList(bytes), ext: 'xlsx', mimeType: MimeType.microsoftExcel);
    _showSuccess(context, 'Exported to Excel');
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export Excel: $e')));
  } finally {
    Navigator.of(context, rootNavigator: true).maybePop();
  }
}

Future<void> _exportCustomersPdf(BuildContext context) async {
  try {
    _showProcessing(context, 'Exporting to PDF...');
    final c = Get.find<CustomerController>();
    final pdf = pw.Document();
    final headers = ['Code','Name','Phone','Email','GSTIN','Total Sale','Due','Status'];
    final list = c.filteredCustomers.isNotEmpty ? c.filteredCustomers : c.customers;
    final rows = <List<String>>[
      for (final x in list)
        [ _codeForStatic(x), x.name, x.phone, x.email ?? '-', x.gstin ?? '-', x.totalPurchases.toStringAsFixed(2), x.dueAmount.toStringAsFixed(2), x.dueAmount > 0 ? 'Due' : 'OK' ]
    ];
    pdf.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4.landscape, build: (_) => [
      pw.Text('Customers Export', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 12),
      pw.Table.fromTextArray(headers: headers, data: rows),
    ]));
    final bytes = await pdf.save();
    await FileSaver.instance.saveFile(name: 'customers_export', bytes: Uint8List.fromList(bytes), ext: 'pdf', mimeType: MimeType.pdf);
    _showSuccess(context, 'Exported to PDF');
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export PDF: $e')));
  } finally {
    Navigator.of(context, rootNavigator: true).maybePop();
  }
}

String _codeForStatic(Customer c) {
  final base = c.id.replaceAll(RegExp('[^A-Z0-9]'), '').toUpperCase();
  final tail = base.length >= 6 ? base.substring(base.length - 6) : base.padLeft(6, '0');
  return 'CUST-$tail';
}
