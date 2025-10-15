import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/bill_controller.dart';
import '../../models/bill_model.dart';
import '../billing/bill_creation_screen.dart';
import '../billing/bill_detail_screen.dart';

class BillHistoryScreen extends StatelessWidget {
  BillHistoryScreen({super.key});

  final BillController billController = Get.find<BillController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bill History')),
      body: Obx(() {
        if (billController.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final bills = billController.filteredBills;
        if (bills.isEmpty) {
          return const Center(child: Text('No bills found'));
        }
        return ListView.separated(
          itemCount: bills.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (context, index) {
            final bill = bills[index];
            return ListTile(
              title: Text('${bill.type.name} • ${bill.customerName ?? 'Guest'}'),
              subtitle: Text('${bill.date.toLocal()}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('₹${bill.totalAmount.toStringAsFixed(2)}'),
                      Text(bill.status.name, style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                          Get.to(() => BillCreationScreen(billType: bill.type), arguments: {'editBill': bill});
                          break;
                        case 'delete':
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Bill'),
                              content: const Text('Are you sure you want to delete this bill?'),
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
    );
  }
}


