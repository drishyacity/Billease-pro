import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';
import '../dashboard/dashboard_screen.dart';
import '../customers/customer_list_screen.dart';
import '../products/product_list_screen.dart';
import '../billing/billing_screen.dart';

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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              Get.offAll(() => const DashboardScreen());
              break;
            case 1:
              Get.offAll(() => const CustomerListScreen());
              break;
            case 2:
              Get.offAll(() => ProductListScreen());
              break;
            case 3:
              Get.offAll(() => const BillingScreen());
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Customers'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt), label: 'Billing'),
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


