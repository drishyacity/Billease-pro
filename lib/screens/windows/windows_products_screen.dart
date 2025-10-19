import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:billease_pro/controllers/product_controller.dart';
import 'package:billease_pro/models/product_model.dart' as model;
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';
import 'package:billease_pro/screens/products/near_expiry_grouped_screen.dart';

class WindowsProductsScreen extends StatefulWidget {
  const WindowsProductsScreen({super.key});

  @override
  State<WindowsProductsScreen> createState() => _WindowsProductsScreenState();
}

class _WindowsProductsScreenState extends State<WindowsProductsScreen> {
  final ProductController controller = Get.find<ProductController>();
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
              Text('Selected: ${_selectedIds.length}'),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _selectedIds.isEmpty ? null : () async {
                  final list = List<model.Product>.from(controller.products);
                  for (final id in _selectedIds.toList()) {
                    final p = list.firstWhereOrNull((e) => e.id == id);
                    if (p != null) {
                      await controller.deleteProduct(p.id);
                    }
                  }
                  setState(() => _selectedIds.clear());
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete Selected'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _selectedIds.isEmpty ? null : () async {
                  final list = (controller.filteredProducts.isNotEmpty ? controller.filteredProducts : controller.products)
                      .where((e) => _selectedIds.contains(e.id))
                      .cast<model.Product>()
                      .toList();
                  final csv = StringBuffer('Name,Category,Stock,Price\n');
                  for (final p in list) {
                    final price = p.batches.isNotEmpty ? p.batches.first.sellingPrice : 0.0;
                    csv.writeln('"${p.name}","${p.category ?? ''}",${p.totalStock.toStringAsFixed(0)},${price.toStringAsFixed(2)}');
                  }
                  final bytes = Uint8List.fromList(csv.toString().codeUnits);
                  await FileSaver.instance.saveFile(name: 'products_export', bytes: bytes, ext: 'csv', mimeType: MimeType.csv);
                },
                icon: const Icon(Icons.download),
                label: const Text('Export CSV'),
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
                    DataColumn(
                      label: const Text('Category'),
                      onSort: (i, asc) => _sort<String>((p) => (p.category ?? '').toLowerCase(), i, asc),
                    ),
                    DataColumn(
                      numeric: true,
                      label: const Text('Stock'),
                      onSort: (i, asc) => _sort<num>((p) => p.totalStock, i, asc),
                    ),
                    DataColumn(
                      numeric: true,
                      label: const Text('Price'),
                      onSort: (i, asc) => _sort<num>((p) => (p.batches.isNotEmpty ? p.batches.first.sellingPrice : 0.0), i, asc),
                    ),
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
        DataCell(Text(p.category ?? '-')),
        DataCell(Text(p.totalStock.toStringAsFixed(0))),
        DataCell(Text((p.batches.isNotEmpty ? p.batches.first.sellingPrice : 0.0).toStringAsFixed(2))),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => items.length;

  @override
  int get selectedRowCount => 0;
}
