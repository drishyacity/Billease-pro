import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/bill_controller.dart';
import '../../models/bill_model.dart';
import 'bill_detail_screen.dart';
import '../../widgets/loading_widget.dart';

class EstimateHistoryScreen extends StatefulWidget {
  const EstimateHistoryScreen({super.key});

  @override
  State<EstimateHistoryScreen> createState() => _EstimateHistoryScreenState();
}

class _EstimateHistoryScreenState extends State<EstimateHistoryScreen> {
  final BillController billController = Get.find();

  @override
  void initState() {
    super.initState();
    billController.loadBills();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rough Estimates')),
      body: Obx(() {
        if (billController.isLoading) {
          return const Center(child: LoadingWidget());
        }
        final List<Bill> estimates = billController.bills
            .where((b) => (b.notes ?? '').toLowerCase() == 'estimate')
            .toList();
        if (estimates.isEmpty) {
          return const Center(child: Text('No rough estimates found'));
        }
        return ListView.builder(
          itemCount: estimates.length,
          itemBuilder: (context, index) {
            final bill = estimates[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text('Estimate #${bill.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date: ${_formatDate(bill.date)}'),
                    if (bill.customerId != null && bill.customerId!.isNotEmpty)
                      Text('Customer ID: ${bill.customerId}'),
                    Text('Items: ${bill.items.length}'),
                    if (bill.gstEnabled)
                      Text('GST: ${bill.inlineGst ? 'Inline (CGST/SGST on each line)' : 'Total (on subtotal)'}'),
                    if (bill.finalDiscountValue > 0)
                      Text('Final Discount: ' + (bill.finalDiscountIsPercent
                          ? '${bill.finalDiscountValue.toStringAsFixed(2)}%'
                          : '₹${bill.finalDiscountValue.toStringAsFixed(2)}')),
                    if ((bill.extraAmount) > 0)
                      Text('${bill.extraAmountName?.isNotEmpty == true ? bill.extraAmountName : 'Extra'}: +₹${bill.extraAmount.toStringAsFixed(2)}'),
                  ],
                ),
                trailing: Text('₹${bill.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () => Get.to(() => BillDetailScreen(bill: bill)),
              ),
            );
          },
        );
      }),
    );
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
}
