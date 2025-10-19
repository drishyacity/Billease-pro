import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:billease_pro/controllers/product_controller.dart';
import 'package:billease_pro/models/product_model.dart' as model;
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import 'package:excel/excel.dart' as ex;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:billease_pro/screens/products/near_expiry_grouped_screen.dart';

class WindowsProductsScreen extends StatefulWidget {
  const WindowsProductsScreen({super.key});

  @override
  State<WindowsProductsScreen> createState() => _WindowsProductsScreenState();
}

// ===== Helpers: Export/Import for Windows Products Screen =====

CellValue? _toCellValue(Object? e) {
  if (e == null) return null;
  if (e is num) return ex.DoubleCellValue(e.toDouble());
  return ex.TextCellValue(e.toString());
}

Future<void> _downloadSampleExcel(BuildContext context) async {
  try {
    final excel = ex.Excel.createExcel();
    const sheetName = 'Products';
    if (excel.sheets.keys.contains('Sheet1')) {
      excel.rename('Sheet1', sheetName);
    }
    excel.setDefaultSheet(sheetName);
    final sheet = excel[sheetName];
    final headers = ['name','barcode','category','unit','cost_price','selling_price','mrp','stock','expiry_date'];
    sheet.appendRow(headers.map((h) => ex.TextCellValue(h)).toList());
    final sample = ['Paracetamol 500mg','8901234567890','Medicines','piece',1.5,2.0,2.5,100,'2026-03-31'];
    sheet.appendRow(sample.map<ex.CellValue?>((e) => _toCellValue(e)).toList());
    final bytes = excel.encode()!;
    await FileSaver.instance.saveFile(name: 'products_sample', bytes: Uint8List.fromList(bytes), ext: 'xlsx', mimeType: MimeType.microsoftExcel);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create sample: $e')));
  }
}

Future<void> _exportAsExcel(BuildContext context) async {
  try {
    final controller = Get.find<ProductController>();
    final excel = ex.Excel.createExcel();
    const sheetName = 'Products';
    if (excel.sheets.keys.contains('Sheet1')) {
      excel.rename('Sheet1', sheetName);
    }
    excel.setDefaultSheet(sheetName);
    final sheet = excel[sheetName];
    final headers = ['name','barcode','category','unit','cost_price','selling_price','mrp','stock','expiry_date','cgst_percent','sgst_percent','discount_percent'];
    sheet.appendRow(headers.map<ex.CellValue?>((h) => ex.TextCellValue(h)).toList());
    final list = controller.hasActiveFilters ? controller.filteredProducts : controller.products;
    for (final p in list) {
      final first = p.batches.isNotEmpty ? p.batches.first : null;
      final row = [
        p.name,
        p.barcode ?? '',
        p.category ?? '',
        p.primaryUnit,
        first?.costPrice ?? 0,
        first?.sellingPrice ?? 0,
        first?.mrp ?? 0,
        p.totalStock,
        first?.expiryDate?.toIso8601String().split('T').first ?? '',
        p.cgstPercentage,
        p.sgstPercentage,
        p.discountPercentage,
      ];
      sheet.appendRow(row.map<ex.CellValue?>((e) => _toCellValue(e)).toList());
    }
    final bytes = excel.encode()!;
    await FileSaver.instance.saveFile(name: 'products_export', bytes: Uint8List.fromList(bytes), ext: 'xlsx', mimeType: MimeType.microsoftExcel);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export Excel: $e')));
  }
}

Future<void> _exportAsPdf(BuildContext context) async {
  try {
    final controller = Get.find<ProductController>();
    final pdf = pw.Document();
    final headers = ['Name','Barcode','Category','Unit','MRP','Selling Price','Cost Price','Stock','Expiry','CGST %','SGST %','Discount %'];
    final list = controller.hasActiveFilters ? controller.filteredProducts : controller.products;
    final rows = <List<String>>[];
    for (final p in list) {
      final first = p.batches.isNotEmpty ? p.batches.first : null;
      rows.add([
        p.name,
        p.barcode ?? '',
        p.category ?? '',
        p.primaryUnit,
        (first?.mrp ?? 0).toStringAsFixed(2),
        (first?.sellingPrice ?? 0).toStringAsFixed(2),
        (first?.costPrice ?? 0).toStringAsFixed(2),
        p.totalStock.toStringAsFixed(0),
        first?.expiryDate?.toIso8601String().split('T').first ?? '',
        p.cgstPercentage.toStringAsFixed(2),
        p.sgstPercentage.toStringAsFixed(2),
        p.discountPercentage.toStringAsFixed(2),
      ]);
    }
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text('Products Export', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(headers: headers, data: rows),
        ],
      ),
    );
    final bytes = await pdf.save();
    await FileSaver.instance.saveFile(name: 'products_export', bytes: Uint8List.fromList(bytes), ext: 'pdf', mimeType: MimeType.pdf);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export PDF: $e')));
  }
}

Future<void> _importFromExcel(BuildContext context) async {
  try {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
    if (result == null || result.files.isEmpty) return;
    final fileBytes = result.files.first.bytes ?? await File(result.files.first.path!).readAsBytes();
    final excel = ex.Excel.decodeBytes(fileBytes);
    final sheet = excel.tables[excel.sheets.keys.first]!;
    final headers = sheet.rows.first.map((c) => c?.value.toString().trim().toLowerCase()).toList();
    int idxOf(String name) => headers.indexOf(name);
    final db = DatabaseService();
    for (int r = 1; r < sheet.rows.length; r++) {
      final row = sheet.rows[r];
      String val(int idx) => (idx >= 0 && idx < row.length ? (row[idx]?.value?.toString() ?? '') : '').trim();
      double numVal(int idx) => double.tryParse(val(idx)) ?? 0.0;
      final id = 'PRD_${DateTime.now().microsecondsSinceEpoch}_$r';
      final name = val(idxOf('name'));
      if (name.isEmpty) continue;
      final now = DateTime.now();
      await db.upsertProduct({
        'id': id,
        'name': name,
        'barcode': val(idxOf('barcode')),
        'category': val(idxOf('category')),
        'primaryUnit': val(idxOf('unit')).isEmpty ? 'piece' : val(idxOf('unit')),
        'gstPercentage': 0,
        'lowStockAlert': 10,
        'expiryAlertDays': 30,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });
      final batchId = 'BATCH_${id}_1';
      final expiry = val(idxOf('expiry_date'));
      await db.insertBatch({
        'id': batchId,
        'product_id': id,
        'name': 'Default',
        'cost_price': numVal(idxOf('cost_price')),
        'selling_price': numVal(idxOf('selling_price')),
        'mrp': numVal(idxOf('mrp')),
        'expiry_date': expiry.isEmpty ? null : expiry,
        'stock': numVal(idxOf('stock')).toInt(),
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import completed')));
    await Get.find<ProductController>().loadProducts();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to import: $e')));
  }
}

class _WindowsProductsScreenState extends State<WindowsProductsScreen> {
  final ProductController controller = Get.find<ProductController>();
  final TextEditingController _searchCtrl = TextEditingController();
  int? _sortColumnIndex;
  bool _sortAscending = true;
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  final Set<String> _selectedIds = <String>{};

  void _sort<T>(Comparable<T> Function(model.Product p) getField, int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      final list = controller.filteredProducts.isNotEmpty ? controller.filteredProducts : controller.products;
      list.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        final cmp = Comparable.compare(aValue, bValue);
        return ascending ? cmp : -cmp;
      });
    });
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
              const Expanded(child: Text('Products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              OutlinedButton.icon(
                onPressed: () { Get.to(() => NearExpiryGroupedScreen()); },
                icon: const Icon(Icons.calendar_month),
                label: const Text('Near Expiry (Grouped)'),
              ),
              Wrap(spacing: 8, children: [
                OutlinedButton.icon(onPressed: () { controller.setStockExpiryFilters(lowStock: true, nearExpiry: false, expired: false); }, icon: const Icon(Icons.warning_amber), label: const Text('Low Stock')),
                OutlinedButton.icon(onPressed: () { controller.setStockExpiryFilters(lowStock: false, nearExpiry: true, expired: false); }, icon: const Icon(Icons.timer), label: const Text('Near Expiry')),
                OutlinedButton.icon(onPressed: () { controller.setStockExpiryFilters(lowStock: false, nearExpiry: false, expired: true); }, icon: const Icon(Icons.event_busy), label: const Text('Expired')),
                OutlinedButton.icon(onPressed: () { controller.setStockExpiryFilters(lowStock: false, nearExpiry: false, expired: false); }, icon: const Icon(Icons.clear_all), label: const Text('Clear')),
              ]),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by name, barcode, id'),
                  onChanged: (v) => setState(() => controller.filterProducts(v)),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: () async { await _exportAsExcel(context); },
                icon: const Icon(Icons.grid_on),
                label: const Text('Export Excel'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async { await _exportAsPdf(context); },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async { await _downloadSampleExcel(context); },
                icon: const Icon(Icons.download_for_offline),
                label: const Text('Sample Excel'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Selected: ${_selectedIds.length}'),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _selectedIds.isEmpty ? null : () async {
                  final list = List<model.Product>.from(controller.products);
                  for (final id in _selectedIds.toList()) {
                    final matches = list.where((e) => e.id == id);
                    if (matches.isNotEmpty) {
                      await controller.deleteProduct(matches.first.id);
                    }
                  }
                  setState(() => _selectedIds.clear());
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Selected'),
              ),
              const SizedBox(width: 8),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () async { await _importFromExcel(context); },
                icon: const Icon(Icons.upload_file),
                label: const Text('Import from Excel'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              final data = controller.filteredProducts.isNotEmpty ? controller.filteredProducts : controller.products;
              final List<model.Product> list = List<model.Product>.from(data);
              final source = _ProductTableSource(list, _selectedIds, onSelectionChanged: (id, sel) {
                setState(() {
                  if (sel) {
                    _selectedIds.add(id);
                  } else {
                    _selectedIds.remove(id);
                  }
                });
              });
              return Card(
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: PaginatedDataTable(
                    header: const Text('Inventory'),
                    rowsPerPage: _rowsPerPage,
                    availableRowsPerPage: const [10, 25, 50, 100],
                    onRowsPerPageChanged: (v) => setState(() => _rowsPerPage = v ?? _rowsPerPage),
                    sortColumnIndex: _sortColumnIndex,
                    sortAscending: _sortAscending,
                    columns: [
                      DataColumn(
                        label: const Text('Name'),
                        onSort: (i, asc) => _sort<String>((p) => p.name.toLowerCase(), i, asc),
                      ),
                      const DataColumn(label: Text('Barcode/HSN')),
                      const DataColumn(label: Text('Unit')),
                      DataColumn(
                        label: const Text('Category'),
                        onSort: (i, asc) => _sort<String>((p) => (p.category ?? '').toLowerCase(), i, asc),
                      ),
                      DataColumn(
                        numeric: true,
                        label: const Text('Stock'),
                        onSort: (i, asc) => _sort<num>((p) => p.totalStock, i, asc),
                      ),
                      const DataColumn(numeric: true, label: Text('Cost')),
                      const DataColumn(numeric: true, label: Text('MRP')),
                      DataColumn(
                        numeric: true,
                        label: const Text('Selling'),
                        onSort: (i, asc) => _sort<num>((p) => (p.batches.isNotEmpty ? p.batches.first.sellingPrice : 0.0), i, asc),
                      ),
                      const DataColumn(numeric: true, label: Text('CGST %')),
                      const DataColumn(numeric: true, label: Text('SGST %')),
                      const DataColumn(numeric: true, label: Text('Discount %')),
                      const DataColumn(label: Text('Status')),
                      const DataColumn(label: Text('Actions')),
                    ],
                    source: source,
                    onSelectAll: (v) {
                      setState(() {
                        if (v == true) {
                          _selectedIds.addAll(list.map((e) => e.id));
                        } else {
                          _selectedIds.clear();
                        }
                      });
                    },
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ProductTableSource extends DataTableSource {
  final List<model.Product> items;
  final Set<String> selectedIds;
  final void Function(String id, bool selected) onSelectionChanged;
  _ProductTableSource(this.items, this.selectedIds, {required this.onSelectionChanged});

  @override
  DataRow? getRow(int index) {
    if (index >= items.length) return null;
    final p = items[index];
    return DataRow.byIndex(
      index: index,
      selected: selectedIds.contains(p.id),
      onSelectChanged: (sel) {
        if (sel == null) return;
        onSelectionChanged(p.id, sel);
        notifyListeners();
      },
      cells: [
        DataCell(Text(p.name)),
        DataCell(Text(p.barcode ?? '-')),
        DataCell(Text(p.primaryUnit)),
        DataCell(Text(p.category ?? '-')),
        DataCell(Text(p.totalStock.toStringAsFixed(0))),
        DataCell(Text((p.batches.isNotEmpty ? p.batches.first.costPrice : 0.0).toStringAsFixed(2))),
        DataCell(Text((p.batches.isNotEmpty ? p.batches.first.mrp : 0.0).toStringAsFixed(2))),
        DataCell(Text((p.batches.isNotEmpty ? p.batches.first.sellingPrice : 0.0).toStringAsFixed(2))),
        DataCell(Text(p.cgstPercentage.toStringAsFixed(2))),
        DataCell(Text(p.sgstPercentage.toStringAsFixed(2))),
        DataCell(Text(p.discountPercentage.toStringAsFixed(2))),
        DataCell(Text(_statusFor(p))),
        DataCell(Row(children: [
          IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit', onPressed: () {/* TODO: open edit */}),
          IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Delete', onPressed: () {/* TODO: delete single */}),
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

  String _statusFor(model.Product p) {
    if (p.hasExpiredBatches()) return 'Expired';
    if (p.hasNearExpiryBatches()) return 'Near Expiry';
    if (p.isLowStock) return 'Low Stock';
    return 'OK';
  }
}
