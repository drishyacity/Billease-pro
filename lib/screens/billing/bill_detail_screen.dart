import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/bill_controller.dart';
import '../../models/bill_model.dart';

class BillDetailScreen extends StatelessWidget {
  final Bill bill;
  
  const BillDetailScreen({
    Key? key,
    required this.bill,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bill #${bill.id.substring(0, 8)}'),
        backgroundColor: _getBillTypeColor(bill.type),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              Get.snackbar(
                'Coming Soon',
                'Print functionality will be available soon',
                snackPosition: SnackPosition.BOTTOM,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBillHeader(),
            const SizedBox(height: 16),
            _buildItemsList(),
            const SizedBox(height: 16),
            _buildBillSummary(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBillHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bill #${bill.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getBillTypeColor(bill.type).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    bill.type.toString().split('.').last,
                    style: TextStyle(
                      color: _getBillTypeColor(bill.type),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${bill.date.toString().substring(0, 10)}',
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
            if (bill.customerId != null && bill.customerId!.isNotEmpty) ...[  
              const SizedBox(height: 8),
              Text(
                'Customer ID: ${bill.customerId}',
                style: TextStyle(
                  color: Colors.grey[700],
                ),
              ),
            ],
            if (bill.notes != null && bill.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${bill.notes}',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildItemsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bill.items.length,
              itemBuilder: (context, index) {
                final item = bill.items[index];
                return ListTile(
                  title: Text(item.productName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${item.quantity} x ₹${item.unitPrice.toStringAsFixed(2)}'),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 16,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('MRP: '),
                          Text(
                            item.mrpOverride != null
                                ? '₹${(item.mrpOverride!).toStringAsFixed(2)}'
                                : '—',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const Text('Expiry: '),
                          Text(
                            item.expiryOverride == null
                                ? '—'
                                : '${item.expiryOverride!.day}/${item.expiryOverride!.month}/${item.expiryOverride!.year}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Text(
                    '₹${(item.quantity * item.unitPrice).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
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
  
  Widget _buildBillSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount:'),
                Text(
                  '₹${bill.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getBillTypeColor(BillType type) {
    switch (type) {
      case BillType.quickSale:
        return Colors.green;
      case BillType.retail:
        return Colors.purple;
      case BillType.wholesale:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  Color _getBillStatusColor(BillStatus status) {
    switch (status) {
      case BillStatus.draft:
        return Colors.grey;
      case BillStatus.partiallyPaid:
        return Colors.orange;
      case BillStatus.fullyPaid:
        return Colors.green;
      case BillStatus.completed:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}