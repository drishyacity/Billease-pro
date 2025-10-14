import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';
import '../../models/product_model.dart';
import 'product_form_screen.dart';
 import '../../services/database_service.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  final ProductController productController = Get.find<ProductController>();

  ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Get.to(ProductFormScreen(product: product)),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildBatchesCard(),
            const SizedBox(height: 16),
            _buildUnitsCard(),
          ],
        ),
      ),
    );
  }

  void _showEditBatchDialog(ProductBatch batch) {
    final name = TextEditingController(text: batch.name);
    final mrp = TextEditingController(text: batch.mrp.toString());
    final sp = TextEditingController(text: batch.sellingPrice.toString());
    final cp = TextEditingController(text: batch.costPrice.toString());
    final stock = TextEditingController(text: batch.stock.toString());
    DateTime? expiry = batch.expiryDate;

    showDialog(
      context: Get.context!,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Batch'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Batch Name')),
                TextField(controller: cp, decoration: const InputDecoration(labelText: 'Cost Price'), keyboardType: TextInputType.number),
                TextField(controller: sp, decoration: const InputDecoration(labelText: 'Selling Price'), keyboardType: TextInputType.number),
                TextField(controller: mrp, decoration: const InputDecoration(labelText: 'MRP'), keyboardType: TextInputType.number),
                TextField(controller: stock, decoration: const InputDecoration(labelText: 'Stock'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: expiry ?? DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setState(() => expiry = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Expiry Date (optional)'),
                    child: Text(expiry == null ? 'Not set' : '${expiry!.day}/${expiry!.month}/${expiry!.year}'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await DatabaseService().updateBatch({
                  'id': batch.id,
                  'product_id': product.id,
                  'name': name.text.trim().isEmpty ? batch.name : name.text.trim(),
                  'cost_price': double.tryParse(cp.text) ?? batch.costPrice,
                  'selling_price': double.tryParse(sp.text) ?? batch.sellingPrice,
                  'mrp': double.tryParse(mrp.text) ?? batch.mrp,
                  'expiry_date': expiry?.toIso8601String(),
                  'stock': int.tryParse(stock.text) ?? batch.stock,
                });
                productController.loadProducts();
                Navigator.pop(context);
                Get.snackbar('Saved', 'Batch updated', snackPosition: SnackPosition.BOTTOM);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Product Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('ID', product.id),
            if (product.barcode != null) _buildInfoRow('Barcode', product.barcode!),
            _buildInfoRow('Category', product.category ?? 'Not specified'),
            _buildInfoRow('Primary Unit', product.primaryUnit),
            _buildInfoRow('GST', '${product.gstPercentage}%'),
            _buildInfoRow('Low Stock Alert', '${product.lowStockAlert} ${product.primaryUnit}'),
            _buildInfoRow('Expiry Alert', '${product.expiryAlertDays} days'),
            _buildInfoRow('Created', _formatDate(product.createdAt)),
            _buildInfoRow('Last Updated', _formatDate(product.updatedAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Batches',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Batch'),
                  onPressed: () => _showAddBatchDialog(),
                ),
              ],
            ),
            const Divider(),
            if (product.batches.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No batches available'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: product.batches.length,
                itemBuilder: (context, index) {
                  final batch = product.batches[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                batch.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Stock: ${batch.stock} ${product.primaryUnit}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: batch.stock <= product.lowStockAlert
                                          ? Colors.red
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'Edit Batch',
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () => _showEditBatchDialog(batch),
                                  ),
                                  IconButton(
                                    tooltip: 'Delete Batch',
                                    icon: const Icon(Icons.delete_outline, size: 20),
                                    onPressed: () async {
                                      await DatabaseService().deleteBatchById(batch.id);
                                      productController.loadProducts();
                                      Get.snackbar('Deleted', 'Batch removed', snackPosition: SnackPosition.BOTTOM);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildPriceColumn('Cost Price', batch.costPrice),
                              _buildPriceColumn('Selling Price', batch.sellingPrice),
                              _buildPriceColumn('MRP', batch.mrp),
                            ],
                          ),
                          if (batch.expiryDate != null) ...[
                            const SizedBox(height: 8),
                            _buildExpiryInfo(batch.expiryDate!),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAddBatchDialog() {
    final name = TextEditingController(text: 'Batch ${product.batches.length + 1}');
    final mrp = TextEditingController();
    final sp = TextEditingController();
    final cp = TextEditingController();
    final stock = TextEditingController();
    DateTime? expiry;

    showDialog(
      context: Get.context!,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Batch'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Batch Name')),
                TextField(controller: cp, decoration: const InputDecoration(labelText: 'Cost Price'), keyboardType: TextInputType.number),
                TextField(controller: sp, decoration: const InputDecoration(labelText: 'Selling Price'), keyboardType: TextInputType.number),
                TextField(controller: mrp, decoration: const InputDecoration(labelText: 'MRP'), keyboardType: TextInputType.number),
                TextField(controller: stock, decoration: const InputDecoration(labelText: 'Opening Stock'), keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 365)),
                      firstDate: DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) setState(() => expiry = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Expiry Date (optional)'),
                    child: Text(expiry == null ? 'Not set' : '${expiry!.day}/${expiry!.month}/${expiry!.year}'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final id = 'BATCH_${product.id}_${DateTime.now().millisecondsSinceEpoch}';
                await DatabaseService().insertBatch({
                  'id': id,
                  'product_id': product.id,
                  'name': name.text.trim().isEmpty ? 'Batch' : name.text.trim(),
                  'cost_price': double.tryParse(cp.text) ?? 0.0,
                  'selling_price': double.tryParse(sp.text) ?? 0.0,
                  'mrp': double.tryParse(mrp.text) ?? 0.0,
                  'expiry_date': expiry?.toIso8601String(),
                  'stock': int.tryParse(stock.text) ?? 0,
                });
                productController.loadProducts();
                Navigator.pop(context);
                Get.snackbar('Success', 'Batch added', snackPosition: SnackPosition.BOTTOM);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Unit Conversions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Conversion'),
                  onPressed: () {
                    // Implement add unit conversion functionality
                    Get.snackbar(
                      'Coming Soon',
                      'Add unit conversion functionality will be implemented soon',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            if (product.unitConversions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No unit conversions available'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: product.unitConversions.length,
                itemBuilder: (context, index) {
                  final conversion = product.unitConversions[index];
                  return ListTile(
                    title: Text(
                      '1 ${conversion.convertedUnit} = ${conversion.conversionFactor} ${conversion.baseUnit}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        // Implement delete unit conversion functionality
                        Get.snackbar(
                          'Coming Soon',
                          'Delete unit conversion functionality will be implemented soon',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceColumn(String label, double price) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          '₹${price.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildExpiryInfo(DateTime expiryDate) {
    final now = DateTime.now();
    final daysToExpiry = expiryDate.difference(now).inDays;
    
    Color color = Colors.green;
    String status = 'Valid';
    
    if (daysToExpiry < 0) {
      color = Colors.red.shade900;
      status = 'Expired';
    } else if (daysToExpiry <= product.expiryAlertDays) {
      color = Colors.orange;
      status = 'Near Expiry';
    }
    
    return Row(
      children: [
        Text(
          'Expiry: ${_formatDate(expiryDate)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              productController.deleteProduct(product.id);
              Navigator.pop(context);
              Get.back();
              Get.snackbar(
                'Product Deleted',
                '${product.name} has been deleted successfully',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}