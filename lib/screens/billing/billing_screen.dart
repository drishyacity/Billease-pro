import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/bill_controller.dart';
import '../../models/bill_model.dart';
import 'bill_detail_screen.dart';
import 'bill_creation_screen.dart';
import '../../widgets/loading_widget.dart';
// Bill history is only available from the dashboard now
import '../settings/settings_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../customers/customer_list_screen.dart';
import '../products/product_list_screen.dart';

class BillingScreen extends StatefulWidget {
  final String? initialBillType;
  final int? initialTabIndex;
  final bool showTodayOnly;
  
  const BillingScreen({Key? key, this.initialBillType, this.initialTabIndex, this.showTodayOnly = false}) : super(key: key);

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final BillController billController = Get.find();
  
  @override
  void initState() {
    super.initState();
    billController.loadBills();
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
        elevation: 2,
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Get.to(() => const SettingsScreen()),
          ),
        ],
      ),
      body: _buildCreateBillOptions(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
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
              // Already on Billing
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
  
  Widget _buildCreateBillOptions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Select Bill Type',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildBillTypeCard(
            title: 'Quick Sale',
            description: 'Fast billing without customer details',
            icon: Icons.flash_on,
            color: Colors.green,
            onTap: () => _navigateToBillCreation(BillType.quickSale),
          ),
          const SizedBox(height: 16),
          _buildBillTypeCard(
            title: 'Retail Bill',
            description: 'Regular retail billing with customer details',
            icon: Icons.shopping_bag,
            color: Colors.purple,
            onTap: () => _navigateToBillCreation(BillType.retail),
          ),
          const SizedBox(height: 16),
          _buildBillTypeCard(
            title: 'Wholesale Bill',
            description: 'Wholesale billing with customer details and GST',
            icon: Icons.store,
            color: Colors.blue,
            onTap: () => _navigateToBillCreation(BillType.wholesale),
          ),
          const SizedBox(height: 16),
          _buildBillTypeCard(
            title: 'Rough Estimate',
            description: 'Create a non-bill estimate without saving as bill',
            icon: Icons.description_outlined,
            color: Colors.orange,
            onTap: () => _navigateToEstimate(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBillTypeCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildBillList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search bills',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              billController.filterBills(searchQuery: value);
            },
          ),
        ),
        Expanded(
          child: Obx(() {
            if (billController.isLoading) {
              return const Center(child: LoadingWidget());
            }
            final List<Bill> source = (widget.showTodayOnly
                ? billController.bills.where((b) {
                    final now = DateTime.now();
                    return b.date.year == now.year && b.date.month == now.month && b.date.day == now.day;
                  }).toList()
                : billController.filteredBills)
              // Exclude rough estimates from regular history
              .where((b) => (b.notes ?? '').toLowerCase() != 'estimate')
              .toList();
            if (source.isEmpty) {
              return const Center(
                child: Text('No bills found'),
              );
            }
            return ListView.builder(
              itemCount: source.length,
              itemBuilder: (context, index) {
                final bill = source[index];
                return _buildBillListItem(bill);
              },
            );
          }),
        ),
      ],
    );
  }
  
  Widget _buildBillListItem(Bill bill) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          'Bill #${bill.id.substring(0, 8)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${_formatDate(bill.date)}',
            ),
            if (bill.customerId != null && bill.customerId!.isNotEmpty)
              Text('Customer ID: ${bill.customerId}'),
            Text('Items: ${bill.items.length}'),
            // GST and discount/extra summary
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
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${bill.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            _buildStatusChip(bill.status),
          ],
        ),
        onTap: () => _viewBillDetails(bill),
      ),
    );
  }
  
  Widget _buildStatusChip(BillStatus status) {
    Color color;
    String label;
    
    switch (status) {
      case BillStatus.draft:
        color = Colors.grey;
        label = 'Draft';
        break;
      case BillStatus.completed:
        color = Colors.green;
        label = 'Completed';
        break;
      case BillStatus.partiallyPaid:
        color = Colors.orange;
        label = 'Partially Paid';
        break;
      case BillStatus.fullyPaid:
        color = Colors.blue;
        label = 'Fully Paid';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  void _navigateToBillCreation(BillType billType) {
    Get.to(() => BillCreationScreen(billType: billType));
  }

  void _navigateToEstimate() {
    Get.to(() => BillCreationScreen(billType: BillType.retail), arguments: {'estimate': true});
  }
  
  void _viewBillDetails(Bill bill) {
    Get.to(() => BillDetailScreen(bill: bill));
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}