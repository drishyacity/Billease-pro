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
import 'package:billease_pro/services/database_service.dart';

class WindowsProductsScreen extends StatefulWidget {
  const WindowsProductsScreen({super.key});

  @override
  State<WindowsProductsScreen> createState() => _WindowsProductsScreenState();
}

// ===== Helpers: Export/Import for Windows Products Screen =====

ex.CellValue? _toCellValue(Object? e) {
  if (e == null) return null;
  if (e is num) return ex.DoubleCellValue(e.toDouble());
  return ex.TextCellValue(e.toString());
}

Future<void> _downloadSampleExcel(BuildContext context) async {
  try {
    _showProcessing(context, 'Preparing sample...');
    final excel = ex.Excel.createExcel();
    const sheetName = 'Products';
    final sheet = excel[sheetName];
    final headers = ['name','barcode','category','unit','cost_price','selling_price','mrp','stock','expiry_date'];
    sheet.appendRow(headers.map((h) => ex.TextCellValue(h)).toList());
    final sample = ['Paracetamol 500mg','8901234567890','Medicines','piece',1.5,2.0,2.5,100,'2026-03-31'];
    sheet.appendRow(sample.map<ex.CellValue?>((e) => _toCellValue(e)).toList());
    final bytes = excel.encode()!;
    await FileSaver.instance.saveFile(name: 'products_sample', bytes: Uint8List.fromList(bytes), ext: 'xlsx', mimeType: MimeType.microsoftExcel);
    _showSuccess(context, 'Sample Excel downloaded');
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create sample: $e')));
  } finally {
    Navigator.of(context, rootNavigator: true).maybePop();
  }
}

Future<void> _exportAsExcel(BuildContext context) async {
  try {
    _showProcessing(context, 'Exporting to Excel...');
    final controller = Get.find<ProductController>();
    final excel = ex.Excel.createExcel();
    const sheetName = 'Products';
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
    _showSuccess(context, 'Exported to Excel');
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export Excel: $e')));
  } finally {
    Navigator.of(context, rootNavigator: true).maybePop();
  }
}

Future<void> _exportAsPdf(BuildContext context) async {
  try {
    _showProcessing(context, 'Exporting to PDF...');
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
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Text('Products Export', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.Table.fromTextArray(headers: headers, data: rows),
        ],
      ),
    );
    final bytes = await pdf.save();
    await FileSaver.instance.saveFile(name: 'products_export', bytes: Uint8List.fromList(bytes), ext: 'pdf', mimeType: MimeType.pdf);
    _showSuccess(context, 'Exported to PDF');
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export PDF: $e')));
  } finally {
    Navigator.of(context, rootNavigator: true).maybePop();
  }
}

Future<void> _importFromExcel(BuildContext context) async {
  try {
    _showProcessing(context, 'Importing from Excel...');
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
        'primary_unit': val(idxOf('unit')).isEmpty ? 'piece' : val(idxOf('unit')),
        'gst_percentage': 0,
        'cgst_percentage': numVal(idxOf('cgst_percent')),
        'sgst_percentage': numVal(idxOf('sgst_percent')),
        'discount_percentage': numVal(idxOf('discount_percent')),
        'low_stock_alert': 10,
        'expiry_alert_days': 30,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
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
    _showSuccess(context, 'Import completed');
    await Get.find<ProductController>().loadProducts();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to import: $e')));
  } finally {
    Navigator.of(context, rootNavigator: true).maybePop();
  }
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
              // Removed extra grouped button as requested
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
              const SizedBox(width: 8),
              Obx(() {
                final cats = controller.categories;
                final current = controller.categoryFilter.value;
                return DropdownButton<String>(
                  value: current,
                  hint: const Text('Category'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('All')),
                    for (final c in cats) DropdownMenuItem(value: c, child: Text(c))
                  ],
                  onChanged: (v) => controller.setCategoryFilter(v ?? ''),
                );
              }),
              const Spacer(),
              Obx(() {
                final total = (controller.filteredProducts.isNotEmpty || controller.hasActiveFilters)
                    ? controller.filteredProducts.length
                    : controller.products.length;
                return Text('Total: $total');
              }),
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
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete Selected'),
                      content: Text('Delete ${_selectedIds.length} selected products?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    final list = List<model.Product>.from(controller.products);
                    for (final id in _selectedIds.toList()) {
                      final matches = list.where((e) => e.id == id);
                      if (matches.isNotEmpty) {
                        await controller.deleteProduct(matches.first.id);
                      }
                    }
                    setState(() => _selectedIds.clear());
                  }
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
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Scrollbar(
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        sortColumnIndex: _sortColumnIndex,
                        sortAscending: _sortAscending,
                        columns: [
                          const DataColumn(label: Text('Select')),
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
                          const DataColumn(numeric: true, label: Text('Stock')),
                          const DataColumn(numeric: true, label: Text('Cost')),
                          const DataColumn(numeric: true, label: Text('MRP')),
                          const DataColumn(numeric: true, label: Text('Selling')),
                          const DataColumn(numeric: true, label: Text('CGST %')),
                          const DataColumn(numeric: true, label: Text('SGST %')),
                          const DataColumn(numeric: true, label: Text('Discount %')),
                          const DataColumn(label: Text('Status')),
                          const DataColumn(label: Text('Actions')),
                        ],
                        rows: [
                          for (final p in list)
                            DataRow(
                              selected: _selectedIds.contains(p.id),
                              onSelectChanged: (sel) {
                                setState(() {
                                  if (sel == true) {
                                    _selectedIds.add(p.id);
                                  } else {
                                    _selectedIds.remove(p.id);
                                  }
                                });
                              },
                              cells: [
                                DataCell(Checkbox(
                                  value: _selectedIds.contains(p.id),
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selectedIds.add(p.id);
                                      } else {
                                        _selectedIds.remove(p.id);
                                      }
                                    });
                                  },
                                )),
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
                                DataCell(_statusPill(_statusFor(p))),
                                DataCell(Row(children: [
                                  IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit', onPressed: () {
                                    Get.snackbar('Edit', 'Implement product edit UI', snackPosition: SnackPosition.TOP);
                                  }),
                                  IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Delete', onPressed: () async {
                                    final ok = await showDialog<bool>(
                                      context: Get.context!,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Delete Product'),
                                        content: Text('Are you sure you want to delete ${p.name}?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Cancel')),
                                          FilledButton(onPressed: () => Navigator.pop(_, true), child: const Text('Delete')),
                                        ],
                                      ),
                                    );
                                    if (ok == true) {
                                      await Get.find<ProductController>().deleteProduct(p.id);
                                    }
                                  }),
                                ])),
                              ],
                            ),
                        ],
                      ),
                    ),
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
        DataCell(_statusPill(_statusFor(p))),
        DataCell(Row(children: [
          IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit', onPressed: () {
            // TODO: integrate actual edit product dialog
            Get.snackbar('Edit', 'Implement product edit UI', snackPosition: SnackPosition.TOP);
          }),
          IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Delete', onPressed: () async {
            final ok = await showDialog<bool>(
              context: Get.context!,
              builder: (_) => AlertDialog(
                title: const Text('Delete Product'),
                content: Text('Are you sure you want to delete ${p.name}?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(_, true), child: const Text('Delete')),
                ],
              ),
            );
            if (ok == true) {
              await Get.find<ProductController>().deleteProduct(p.id);
            }
          }),
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

  Widget _statusPill(String status) {
    Color color;
    switch (status) {
      case 'Expired':
        color = Colors.red;
        break;
      case 'Near Expiry':
        color = Colors.orange;
        break;
      case 'Low Stock':
        color = Colors.amber;
        break;
      default:
        color = Colors.green;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }
}
