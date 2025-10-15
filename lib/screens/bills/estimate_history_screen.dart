import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/bill_controller.dart';
import '../../models/bill_model.dart';
import '../billing/bill_creation_screen.dart';
import '../billing/bill_detail_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../customers/customer_list_screen.dart';
import '../products/product_list_screen.dart';
import '../billing/billing_screen.dart';

class EstimateHistoryScreen extends StatelessWidget {
  EstimateHistoryScreen({super.key});

  final BillController billController = Get.find<BillController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estimate History')),
      body: Obx(() {
        final estimates = billController.bills
            .where((b) => b.status == BillStatus.draft && (b.notes == 'estimate'))
            .toList();
        if (estimates.isEmpty) {
          return const Center(child: Text('No estimates found'));
        }
        return ListView.separated(
          itemCount: estimates.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (context, index) {
            final bill = estimates[index];
            return ListTile(
              title: Text('${bill.type.name} • ${bill.customerName ?? 'Customer'}'),
              subtitle: Text('${bill.date.toLocal()}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('₹${bill.totalAmount.toStringAsFixed(2)}'),
                      const Text('Estimate', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
                      switch (value) {
                        case 'view':
                          Get.to(() => BillDetailScreen(bill: bill));
                          break;
                        case 'edit':
                          Get.to(() => BillCreationScreen(billType: bill.type), arguments: {'editBill': bill, 'estimate': true});
                          break;
                        case 'delete':
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Estimate'),
                              content: const Text('Are you sure you want to delete this estimate?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await billController.deleteBill(bill.id);
                          }
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'view', child: Text('View')),
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              onTap: () => Get.to(() => BillDetailScreen(bill: bill)),
            );
          },
        );
      }),
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
}
