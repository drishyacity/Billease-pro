import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';

class ReportsScreen extends StatelessWidget {
  ReportsScreen({super.key});

  final ProductController productController = Get.put(ProductController());

  @override
  Widget build(BuildContext context) {
    final lowStock = productController.getLowStockProducts();
    final nearExpiry = productController.getNearExpiryProducts();
    final expired = productController.getExpiredProducts();

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        children: [
          _section('Low stock', lowStock.map((p) => '${p.name} (${p.totalStock})').toList()),
          _section('Near expiry', nearExpiry.map((p) => p.name).toList()),
          _section('Expired', expired.map((p) => p.name).toList()),
        ],
      ),
    );
  }

  Widget _section(String title, List<String> items) {
    return ExpansionTile(
      title: Text(title),
      children: items.isEmpty
          ? [const ListTile(title: Text('None'))]
          : items.map((e) => ListTile(title: Text(e))).toList(),
    );
  }
}


