import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/bill_controller.dart';
import '../../models/bill_model.dart';

class BillHistoryScreen extends StatelessWidget {
  BillHistoryScreen({super.key});

  final BillController billController = Get.put(BillController());

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
              trailing: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('₹${bill.totalAmount.toStringAsFixed(2)}'),
                  Text(bill.status.name, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}


