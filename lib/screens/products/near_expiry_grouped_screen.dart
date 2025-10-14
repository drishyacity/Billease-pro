import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';
import '../../models/product_model.dart';

class NearExpiryGroupedScreen extends StatelessWidget {
  NearExpiryGroupedScreen({super.key});
  final ProductController productController = Get.find<ProductController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Near Expiry (Grouped)')),
      body: Obx(() {
        final now = DateTime.now();
        // Build map: 'YYYY-MM' -> List<ProductBatch with product)
        final Map<String, List<_BatchWithProduct>> groups = {};
        for (final p in productController.products) {
          for (final b in p.batches) {
            final e = b.expiryDate;
            if (e == null) continue;
            // Only upcoming including current month
            if (e.isBefore(DateTime(now.year, now.month, 1))) continue;
            final key = '${e.year}-${e.month.toString().padLeft(2, '0')}';
            groups.putIfAbsent(key, () => []);
            groups[key]!.add(_BatchWithProduct(product: p, batch: b));
          }
        }
        if (groups.isEmpty) {
          return const Center(child: Text('No near expiry products')); 
        }
        final keys = groups.keys.toList()
          ..sort((a, b) => a.compareTo(b));
        return ListView.builder(
          itemCount: keys.length,
          itemBuilder: (context, index) {
            final key = keys[index];
            final year = int.parse(key.split('-')[0]);
            final month = int.parse(key.split('-')[1]);
            final items = groups[key]!;
            items.sort((x, y) => (x.batch.expiryDate!).compareTo(y.batch.expiryDate!));
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_monthName(month)} $year',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      ...items.map((bp) => ListTile(
                            title: Text(bp.product.name),
                            subtitle: Text('Batch: ${bp.batch.name} • Expiry: ${_formatDate(bp.batch.expiryDate!)}'),
                            trailing: Text('Stock: ${bp.batch.stock} ${bp.product.primaryUnit}'),
                          )),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  String _monthName(int m) {
    const names = [
      'January','February','March','April','May','June','July','August','September','October','November','December'
    ];
    return names[m - 1];
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _BatchWithProduct {
  final Product product;
  final ProductBatch batch;
  _BatchWithProduct({required this.product, required this.batch});
}
