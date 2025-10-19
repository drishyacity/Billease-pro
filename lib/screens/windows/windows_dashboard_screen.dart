import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:billease_pro/controllers/bill_controller.dart';
import 'package:billease_pro/models/bill_model.dart';
import 'package:billease_pro/controllers/product_controller.dart';
import 'package:billease_pro/screens/bills/bill_history_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class WindowsDashboardScreen extends StatelessWidget {
  const WindowsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final billController = Get.find<BillController>();
    final productController = Get.find<ProductController>();

    final today = DateTime.now();
    final todayTotal = billController.bills
        .where((b) => b.status != BillStatus.draft)
        .where((b) => b.date.year == today.year && b.date.month == today.month && b.date.day == today.day)
        .fold<double>(0.0, (sum, b) => sum + b.totalAmount);

    final lowStockCount = productController.products.where((p) => p.isLowStock).length;
    final nearExpiryCount = productController.products.where((p) => p.hasNearExpiryBatches()).length;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text('Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _statCard(context, 'Today\'s Sale', '₹${todayTotal.toStringAsFixed(2)}', Icons.currency_rupee, Colors.teal, onTap: () {
                Get.to(() => const BillHistoryScreen(initialQuick: 'Today'));
              }),
              _statCard(context, 'Low Stock', '$lowStockCount', Icons.warning_amber, Colors.red, onTap: () {
                // Navigate to Products tab with filters in Windows shell
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use Products page filters for Low Stock')));
              }),
              _statCard(context, 'Near Expiry', '$nearExpiryCount', Icons.timer, Colors.orange, onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use Products page filters for Near Expiry')));
              }),
            ],
          ),
          const SizedBox(height: 24),
          _salesChartCard(billController),
          const SizedBox(height: 24),
          const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _actionChip(context, Icons.receipt_long, 'Create Bill', Colors.blue, onTap: () {
                // Switch to Billing page in Windows shell
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Open Billing from sidebar')));
              }),
              _actionChip(context, Icons.people, 'Customers', Colors.orange, onTap: () {}),
              _actionChip(context, Icons.inventory, 'Products', Colors.green, onTap: () {}),
              _actionChip(context, Icons.analytics, 'Reports', Colors.purple, onTap: () {
                Get.to(() => const BillHistoryScreen());
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.18), shape: BoxShape.circle),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: TextStyle(color: color.withOpacity(0.9), fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(BuildContext context, IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [Icon(icon, color: color), const SizedBox(width: 8), Text(label, style: TextStyle(color: color.withOpacity(0.9), fontWeight: FontWeight.w600))]),
      ),
    );
  }

  Widget _salesChartCard(BillController billController) {
    final now = DateTime.now();
    final last7 = List<DateTime>.generate(7, (i) => DateTime(now.year, now.month, now.day - (6 - i)));
    final totals = last7.map((d) {
      final sum = billController.bills
          .where((b) => b.status != BillStatus.draft)
          .where((b) => b.date.year == d.year && b.date.month == d.month && b.date.day == d.day)
          .fold<double>(0.0, (s, b) => s + b.totalAmount);
      return sum;
    }).toList();

    final spots = [
      for (int i = 0; i < totals.length; i++) FlSpot(i.toDouble(), totals[i]),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.blue.withOpacity(0.15))),
      child: SizedBox(
        height: 260,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sales - Last 7 days', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Expanded(
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: 6,
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i > 6) return const SizedBox.shrink();
                        final d = last7[i];
                        return Text('${d.day}/${d.month}', style: const TextStyle(fontSize: 10));
                      })),
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.15)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
