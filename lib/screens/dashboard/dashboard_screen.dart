import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/bill_controller.dart';
import '../../controllers/product_controller.dart';
import '../billing/billing_screen.dart';
import '../customers/customer_list_screen.dart';
import '../products/product_list_screen.dart';
import '../bills/bill_history_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../products/near_expiry_grouped_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final BillController _billController = Get.find<BillController>();
  final ProductController _productController = Get.find<ProductController>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BillEase Pro'),
        elevation: 2,
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Get.to(() => const SettingsScreen()),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
            const Text(
              'Welcome to BillEase Pro',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your complete billing solution',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final spacing = 12.0;
                final columns = constraints.maxWidth < 500 ? 1 : 2;
                final itemWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
                final items = [
                  _buildActionCard(
                    title: 'Create Bill',
                    icon: Icons.receipt_long,
                    color: Colors.blue,
                    onTap: () => Get.to(() => const BillingScreen()),
                  ),
                  _buildActionCard(
                    title: 'Customers',
                    icon: Icons.people,
                    color: Colors.orange,
                    onTap: () => Get.to(() => const CustomerListScreen()),
                  ),
                  _buildActionCard(
                    title: 'Products',
                    icon: Icons.inventory,
                    color: Colors.green,
                    onTap: () => Get.to(() => ProductListScreen()),
                  ),
                  _buildActionCard(
                    title: 'Bill History',
                    icon: Icons.history,
                    color: Colors.purple,
                    onTap: () => Get.to(() => BillHistoryScreen()),
                  ),
                ];
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: items
                      .map((w) => SizedBox(width: itemWidth, child: w))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Today & Alerts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final today = DateTime.now();
              final todayTotal = _billController.bills
                  .where((b) => b.date.year == today.year && b.date.month == today.month && b.date.day == today.day)
                  .fold<double>(0.0, (sum, b) => sum + b.totalAmount);
              final lowStockCount = _productController.products.where((p) => p.isLowStock).length;
              final nearExpiryCount = _productController.products.where((p) => p.hasNearExpiryBatches()).length;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final spacing = 12.0;
                  final columns = constraints.maxWidth < 500 ? 1 : 2;
                  final itemWidth = (constraints.maxWidth - spacing * (columns - 1)) / columns;
                  final stats = [
                    _buildStatCard(
                      title: 'Today\'s Sale',
                      value: '₹${todayTotal.toStringAsFixed(2)}',
                      color: Colors.teal,
                      icon: Icons.currency_rupee,
                      onTap: () {
                        Get.to(() => BillingScreen(initialTabIndex: 1, showTodayOnly: true));
                      },
                    ),
                    _buildStatCard(
                      title: 'Low Stock',
                      value: '$lowStockCount',
                      color: Colors.red,
                      icon: Icons.warning_amber,
                      onTap: () {
                        _productController.setStockExpiryFilters(lowStock: true, nearExpiry: false, expired: false);
                        Get.to(() => ProductListScreen());
                      },
                    ),
                    _buildStatCard(
                      title: 'Near Expiry',
                      value: '$nearExpiryCount',
                      color: Colors.orange,
                      icon: Icons.timer,
                      onTap: () async {
                        final now = DateTime.now();
                        final months = List.generate(12, (i) => i + 1); // 1..12
                        final selected = await showDialog<Map<String,int>?>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Select Month for Near Expiry'),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ...months.map((m) {
                                    final year = m >= now.month ? now.year : now.year + 1;
                                    final label = '${m.toString().padLeft(2,'0')}/$year';
                                    return ListTile(
                                      title: Text(label),
                                      onTap: () => Navigator.pop(context, {'month': m, 'year': year}),
                                    );
                                  }).toList(),
                                  const Divider(),
                                  ListTile(
                                    title: const Text('Show all near expiry (grouped monthly)'),
                                    onTap: () => Navigator.pop(context, {'month': 0, 'year': 0}),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                        if (selected != null) {
                          if (selected['month'] == 0) {
                            _productController.setStockExpiryFilters(nearExpiry: true, lowStock: false, expired: false);
                            _productController.setNearExpiryWithinDays(null);
                            _productController.setNearExpiryMonthYear(month: null, year: null);
                            Get.to(() => NearExpiryGroupedScreen());
                          } else {
                            _productController.setNearExpiryWithinDays(null);
                            _productController.setNearExpiryMonthYear(month: selected['month'], year: selected['year']);
                            _productController.setStockExpiryFilters(nearExpiry: true, lowStock: false, expired: false);
                            Get.to(() => ProductListScreen());
                          }
                        }
                      },
                    ),
                  ];
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: stats
                        .map((w) => SizedBox(width: itemWidth, child: w))
                        .toList(),
                  );
                },
              );
            }),
            const SizedBox(height: 24),
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Get.to(() => ReportsScreen()),
                    icon: const Icon(Icons.analytics),
                    label: const Text('Open Reports'),
                  )
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0: // Dashboard - already here
              break;
            case 1: // Customers
               Get.to(() => const CustomerListScreen());
               break;
            case 2: // Products
              Get.to(() => ProductListScreen());
              break;
            case 3: // Billing
              Get.to(() => const BillingScreen());
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Customers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Billing',
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container
    (
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color.withOpacity(0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}