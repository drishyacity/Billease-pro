import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/customer_model.dart';
import '../../controllers/customer_controller.dart';
import '../../controllers/bill_controller.dart';
import 'customer_form_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;

  const CustomerDetailScreen({Key? key, required this.customer}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Get.to(() => CustomerFormScreen(customer: customer));
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmation(context);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete Customer'),
                ),
              ];
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildPurchaseHistorySection(),
            const SizedBox(height: 16),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow('ID', customer.id),
            _buildInfoRow('Name', customer.name),
            _buildInfoRow('Phone', customer.phone),
            if (customer.email != null && customer.email!.isNotEmpty)
              _buildInfoRow('Email', customer.email!),
            if (customer.address != null && customer.address!.isNotEmpty)
              _buildInfoRow('Address', customer.address!),
            if (customer.gstin != null && customer.gstin!.isNotEmpty)
              _buildInfoRow('GSTIN', customer.gstin!),
            const Divider(),
            _buildInfoRow(
              'Total Purchases',
              '₹${customer.totalPurchases.toStringAsFixed(2)}',
              valueStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
            _buildInfoRow(
              'Due Amount',
              '₹${customer.dueAmount.toStringAsFixed(2)}',
              valueStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: customer.dueAmount > 0 ? Colors.red : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseHistorySection() {
    // Use bills from BillController via Obx to reflect live data
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Purchase History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to detailed purchase history
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            GetX<BillController>(
              init: Get.find<BillController>(),
              builder: (bc) {
                final bills = bc.bills.where((b) => b.customerId == customer.id || b.customerName == customer.name).toList();
                if (bills.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('No purchase history found'),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bills.length.clamp(0, 5),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final bill = bills[index];
                    final due = (bill.totalAmount - bill.paidAmount).clamp(0, double.infinity);
                    final status = due <= 0
                        ? 'Paid'
                        : (bill.paidAmount > 0 ? 'Partially Paid' : 'Unpaid');
                    return _buildPurchaseHistoryItem(
                      bill.id,
                      bill.date,
                      bill.totalAmount,
                      status,
                      dueAmount: (due as num).toDouble(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseHistoryItem(
    String billId,
    DateTime date,
    double amount,
    String status, {
    double dueAmount = 0.0,
  }) {
    Color statusColor;
    switch (status) {
      case 'Paid':
        statusColor = Colors.green;
        break;
      case 'Partially Paid':
        statusColor = Colors.orange;
        break;
      case 'Unpaid':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        'Bill #$billId',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date: ${_formatDate(date)}'),
          if (dueAmount > 0)
            Text(
              'Due: ₹${dueAmount.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.red),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      onTap: () {
        // Navigate to bill details
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          context,
          Icons.receipt,
          'New Bill',
          Colors.blue,
          () {
            // Navigate to create bill with this customer
          },
        ),
        _buildActionButton(
          context,
          Icons.payment,
          'Record Payment',
          Colors.green,
          () {
            // Navigate to record payment
          },
        ),
        _buildActionButton(
          context,
          Icons.history,
          'View History',
          Colors.purple,
          () {
            // Navigate to detailed history
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Customer'),
          content: Text(
            'Are you sure you want to delete ${customer.name}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final customerController = Get.find<CustomerController>();
                customerController.deleteCustomer(customer.id);
                Navigator.of(context).pop();
                Get.back(); // Return to customer list
                Get.snackbar(
                  'Success',
                  'Customer deleted successfully',
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}