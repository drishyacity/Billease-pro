import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';
import '../../models/product_model.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as ex;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'dart:typed_data';
import 'package:file_saver/file_saver.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/database_service.dart';

class ProductListScreen extends StatelessWidget {
  final ProductController productController = Get.find<ProductController>();

  ProductListScreen({Key? key}) : super(key: key);

  ex.CellValue _toCellValue(dynamic v) {
    if (v == null) return ex.TextCellValue('');
    if (v is String) return ex.TextCellValue(v);
    if (v is int) return ex.IntCellValue(v);
    if (v is double) return ex.DoubleCellValue(v);
    if (v is num) return ex.DoubleCellValue(v.toDouble());
    if (v is DateTime) return ex.TextCellValue(v.toIso8601String().split('T').first);
    return ex.TextCellValue(v.toString());
  }

  Future<String?> _getSaveFilePath({
    required String suggestedFileName,
    required List<String> allowedExtensions,
    required String dialogTitle,
  }) async {
    // Windows: let user choose location
    if (Platform.isWindows) {
      return await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: suggestedFileName,
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
      );
    }
    // Non-Windows: we'll use FileSaver instead of returning a path
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _showExportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: () => _showImportDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (productController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search products...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: productController.filterProducts,
              ),
            ),
            Expanded(
              child: productController.filteredProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No products found',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            productController.products.isEmpty
                                ? 'Add your first product to get started'
                                : 'Try adjusting your search or filters',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Product'),
                            onPressed: () => Get.to(ProductFormScreen(product: null)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: productController.filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = productController.filteredProducts[index];
                        return ProductListItem(product: product);
                      },
                    ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => ProductFormScreen(product: null)),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    String? selectedCategory;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Products'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Obx(() {
              final categories = ['All'] + productController.categories;
              return Wrap(
                spacing: 8,
                children: categories.map((category) {
                  final isSelected = category == 'All'
                      ? productController.categoryFilter.value.isEmpty
                      : productController.categoryFilter.value == category;
                  
                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        selectedCategory = category == 'All' ? null : category;
                      }
                    },
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: 16),
            const Text('Stock Status', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Obx(() => Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Low Stock'),
                      selected: productController.lowStockOnly.value,
                      onSelected: (selected) {
                        productController.setStockExpiryFilters(lowStock: selected);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Near Expiry'),
                      selected: productController.nearExpiryOnly.value,
                      onSelected: (selected) {
                        productController.setStockExpiryFilters(nearExpiry: selected);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Expired'),
                      selected: productController.expiredOnly.value,
                      onSelected: (selected) {
                        productController.setStockExpiryFilters(expired: selected);
                      },
                    ),
                  ],
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedCategory != null) {
                productController.setCategoryFilter(
                  selectedCategory == 'All' ? '' : selectedCategory!,
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Products'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              onTap: () async {
                Navigator.pop(context);
                await _exportAsPdf(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as Excel'),
              onTap: () async {
                Navigator.pop(context);
                await _exportAsExcel(context);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download Sample Excel'),
              onTap: () async {
                Navigator.pop(context);
                await _downloadSampleExcel(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Products'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Import products from Excel file. The file should have the following columns:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'name, barcode, category, unit, cost_price, selling_price, mrp, stock, expiry_date(YYYY-MM-DD)',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Select File'),
              onPressed: () async {
                Navigator.pop(context);
                await _importFromExcel(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAsPdf(BuildContext context) async {
    try {
      final pdf = pw.Document();
      final headers = ['Name','Barcode','Category','Unit','MRP','Selling Price','Cost Price','Stock','Expiry'];
      final rows = productController.products.map((p) {
        final first = p.batches.isNotEmpty ? p.batches.first : null;
        return [
          p.name,
          p.barcode ?? '',
          p.category ?? '',
          p.primaryUnit,
          first?.mrp.toStringAsFixed(2) ?? '',
          first?.sellingPrice.toStringAsFixed(2) ?? '',
          first?.costPrice.toStringAsFixed(2) ?? '',
          p.totalStock.toString(),
          first?.expiryDate?.toIso8601String().split('T').first ?? '',
        ];
      }).toList();
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
      if (Platform.isWindows) {
        final savePath = await _getSaveFilePath(
          suggestedFileName: 'products_export.pdf',
          allowedExtensions: const ['pdf'],
          dialogTitle: 'Save Products PDF',
        );
        if (savePath == null) return; // canceled
        final file = File(savePath);
        await file.writeAsBytes(await pdf.save(), flush: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF saved to ${file.path}')),
        );
      } else {
        final bytes = await pdf.save();
        final res = await FileSaver.instance.saveFile(
          name: 'products_export',
          bytes: Uint8List.fromList(bytes),
          ext: 'pdf',
          mimeType: MimeType.pdf,
        );
        final savedPath = res?.toString() ?? '';
        if (savedPath.isEmpty || savedPath.contains('/Android/data/')) {
          // Fallback: open share sheet so user can save to Downloads explicitly
          await Share.shareXFiles([
            XFile.fromData(Uint8List.fromList(bytes), name: 'products_export.pdf', mimeType: 'application/pdf'),
          ], text: 'Save to Downloads');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Choose Downloads in the share dialog to save the file.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF saved successfully.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export PDF: $e')),
      );
    }
  }

  Future<void> _exportAsExcel(BuildContext context) async {
    try {
      final excel = ex.Excel.createExcel();
      const sheetName = 'Products';
      // Use default sheet by renaming it so viewers open the populated sheet
      if (excel.sheets.keys.contains('Sheet1')) {
        excel.rename('Sheet1', sheetName);
      }
      excel.setDefaultSheet(sheetName);
      final sheet = excel[sheetName];
      final headers = ['name','barcode','category','unit','cost_price','selling_price','mrp','stock','expiry_date'];
      sheet.appendRow(headers.map<ex.CellValue?>((h) => ex.TextCellValue(h)).toList());
      for (final p in productController.products) {
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
        ];
        sheet.appendRow(row.map<ex.CellValue?>((e) => _toCellValue(e)).toList());
      }
      final bytes = excel.encode()!;
      if (Platform.isWindows) {
        final savePath = await _getSaveFilePath(
          suggestedFileName: 'products_export.xlsx',
          allowedExtensions: const ['xlsx'],
          dialogTitle: 'Save Products Excel',
        );
        if (savePath == null) return; // canceled
        final file = File(savePath);
        await file.writeAsBytes(bytes, flush: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Excel saved to ${file.path}')),
        );
      } else {
        final res = await FileSaver.instance.saveFile(
          name: 'products_export',
          bytes: Uint8List.fromList(bytes),
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
        final savedPath = res?.toString() ?? '';
        if (savedPath.isEmpty || savedPath.contains('/Android/data/')) {
          await Share.shareXFiles([
            XFile.fromData(Uint8List.fromList(bytes), name: 'products_export.xlsx', mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
          ], text: 'Save to Downloads');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Choose Downloads in the share dialog to save the file.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Excel saved successfully.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export Excel: $e')),
      );
    }
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
      if (Platform.isWindows) {
        final savePath = await _getSaveFilePath(
          suggestedFileName: 'products_sample.xlsx',
          allowedExtensions: const ['xlsx'],
          dialogTitle: 'Save Sample Excel',
        );
        if (savePath == null) return; // canceled
        final file = File(savePath);
        await file.writeAsBytes(bytes, flush: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sample saved to ${file.path}')),
        );
      } else {
        final res = await FileSaver.instance.saveFile(
          name: 'products_sample',
          bytes: Uint8List.fromList(bytes),
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
        final savedPath = res?.toString() ?? '';
        if (savedPath.isEmpty || savedPath.contains('/Android/data/')) {
          await Share.shareXFiles([
            XFile.fromData(Uint8List.fromList(bytes), name: 'products_sample.xlsx', mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
          ], text: 'Save to Downloads');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Choose Downloads in the share dialog to save the file.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sample saved successfully.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create sample: $e')),
      );
    }
  }

  Future<void> _importFromExcel(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.single.bytes ?? await File(result.files.single.path!).readAsBytes();
      final excel = ex.Excel.decodeBytes(bytes);
      final db = DatabaseService();
      final sheet = excel.tables.values.first; // take first sheet
      if (sheet.maxRows <= 1) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data rows found.')));
        return;
      }
      // assume header row at index 0
      for (var r = 1; r < sheet.maxRows; r++) {
        final row = sheet.row(r);
        String getS(int c) => row.length > c && row[c] != null ? row[c]!.value.toString().trim() : '';
        double getD(int c) => row.length > c && row[c] != null ? double.tryParse(row[c]!.value.toString()) ?? 0 : 0;
        int getI(int c) => row.length > c && row[c] != null ? int.tryParse(row[c]!.value.toString()) ?? 0 : 0;
        final name = getS(0);
        final barcode = getS(1);
        final category = getS(2);
        final unit = getS(3).isEmpty ? 'piece' : getS(3);
        final costPrice = getD(4);
        final sellingPrice = getD(5);
        final mrp = getD(6);
        final stock = getI(7);
        final expiryStr = getS(8);
        DateTime? expiryDate;
        if (expiryStr.isNotEmpty) {
          try { expiryDate = DateTime.parse(expiryStr); } catch (_) {}
        }
        if (name.isEmpty) continue;
        final existing = await db.findProductByBarcodeOrName(barcode: barcode.isEmpty ? null : barcode, name: name);
        final now = DateTime.now();
        if (existing == null) {
          final id = DateTime.now().microsecondsSinceEpoch.toString();
          await db.upsertProduct({
            'id': id,
            'name': name,
            'barcode': barcode.isEmpty ? null : barcode,
            'category': category.isEmpty ? null : category,
            'primary_unit': unit,
            'gst_percentage': 0,
            'low_stock_alert': 10,
            'expiry_alert_days': 30,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          });
          // default New/Old based on import row
          final newBatch = {
            'id': 'BATCH_${id}_NEW',
            'product_id': id,
            'name': 'New',
            'cost_price': costPrice,
            'selling_price': sellingPrice,
            'mrp': mrp,
            'expiry_date': expiryDate?.toIso8601String(),
            'stock': stock,
          };
          final oldBatch = {
            'id': 'BATCH_${id}_OLD',
            'product_id': id,
            'name': 'Old',
            'cost_price': costPrice,
            'selling_price': sellingPrice,
            'mrp': mrp,
            'expiry_date': expiryDate?.toIso8601String(),
            'stock': stock,
          };
          await db.insertBatch(newBatch);
          await db.insertBatch(oldBatch);
        } else {
          final id = existing['id'] as String;
          await db.upsertProduct({
            'id': id,
            'name': name,
            'barcode': barcode.isEmpty ? null : barcode,
            'category': category.isEmpty ? null : category,
            'primary_unit': unit,
            'gst_percentage': existing['gst_percentage'] ?? 0,
            'low_stock_alert': existing['low_stock_alert'] ?? 10,
            'expiry_alert_days': existing['expiry_alert_days'] ?? 30,
            'created_at': existing['created_at'],
            'updated_at': now.toIso8601String(),
          });
          // rollover: copy previous New -> Old, then update New
          final batches = await db.getBatchesByProductId(id);
          Map<String, dynamic>? newB;
          Map<String, dynamic>? oldB;
          for (final b in batches) {
            final nm = (b['name'] as String).toLowerCase();
            if (nm == 'new') newB = b;
            if (nm == 'old') oldB = b;
          }
          if (newB != null && oldB != null) {
            await db.updateBatch({
              'id': oldB['id'],
              'product_id': id,
              'name': 'Old',
              'cost_price': newB['cost_price'],
              'selling_price': newB['selling_price'],
              'mrp': newB['mrp'],
              'expiry_date': newB['expiry_date'],
              'stock': newB['stock'],
            });
            await db.updateBatch({
              'id': newB['id'],
              'product_id': id,
              'name': 'New',
              'cost_price': costPrice,
              'selling_price': sellingPrice,
              'mrp': mrp,
              'expiry_date': expiryDate?.toIso8601String(),
              'stock': stock,
            });
          } else {
            // create both if missing
            await db.insertBatch({
              'id': 'BATCH_${id}_NEW',
              'product_id': id,
              'name': 'New',
              'cost_price': costPrice,
              'selling_price': sellingPrice,
              'mrp': mrp,
              'expiry_date': expiryDate?.toIso8601String(),
              'stock': stock,
            });
            await db.insertBatch({
              'id': 'BATCH_${id}_OLD',
              'product_id': id,
              'name': 'Old',
              'cost_price': costPrice,
              'selling_price': sellingPrice,
              'mrp': mrp,
              'expiry_date': expiryDate?.toIso8601String(),
              'stock': stock,
            });
          }
        }
      }
      productController.loadProducts();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import completed')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to import: $e')),
      );
    }
  }
}

class ProductListItem extends StatelessWidget {
  final Product product;

  const ProductListItem({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalStock = product.totalStock;
    final isLowStock = product.isLowStock;
    final hasNearExpiry = product.hasNearExpiryBatches();
    final hasExpired = product.hasExpiredBatches();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => Get.to(() => ProductDetailScreen(product: product)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (product.category != null)
                    Chip(
                      label: Text(
                        product.category!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.blue.shade100,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (product.barcode != null)
                Text(
                  'Barcode: ${product.barcode}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MRP: ₹${product.batches.isNotEmpty ? product.batches.first.mrp.toStringAsFixed(2) : "N/A"}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Stock: $totalStock ${product.primaryUnit}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isLowStock ? Colors.red : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (isLowStock)
                    _buildStatusChip('Low Stock', Colors.red),
                  if (hasNearExpiry)
                    _buildStatusChip('Near Expiry', Colors.orange),
                  if (hasExpired)
                    _buildStatusChip('Expired', Colors.red.shade900),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: color,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class ProductSearchDelegate extends SearchDelegate<String> {
  final ProductController productController;

  ProductSearchDelegate(this.productController);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    productController.filterProducts(query);
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search by name, barcode, or ID',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    productController.filterProducts(query);
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return Obx(() {
      final results = productController.filteredProducts;
      
      if (results.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No products found for "$query"',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
                onPressed: () {
                  close(Get.context!, '');
                  Get.to(() => ProductFormScreen(product: null));
                },
              ),
            ],
          ),
        );
      }
      
      return ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final product = results[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Text(product.barcode ?? 'No barcode'),
            trailing: Text(
              'Stock: ${product.totalStock}',
              style: TextStyle(
                color: product.isLowStock ? Colors.red : Colors.black,
              ),
            ),
            onTap: () {
              close(context, product.id);
              Get.to(() => ProductDetailScreen(product: product));
            },
          );
        },
      );
    });
  }
}