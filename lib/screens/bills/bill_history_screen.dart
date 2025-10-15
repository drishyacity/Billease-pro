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

class BillHistoryScreen extends StatefulWidget {
  final String? initialQuick;
  final DateTime? initialFrom;
  final DateTime? initialTo;
  const BillHistoryScreen({super.key, this.initialQuick, this.initialFrom, this.initialTo});

  @override
  State<BillHistoryScreen> createState() => _BillHistoryScreenState();
}

class _BillHistoryScreenState extends State<BillHistoryScreen> {
  final BillController billController = Get.find<BillController>();
  final TextEditingController _searchCtrl = TextEditingController();
  DateTime? _from;
  DateTime? _to;
  String _quick = 'All';

  @override
  void initState() {
    super.initState();
    // ensure latest bills
    billController.loadBills();
    // apply initial filters if provided
    if (widget.initialFrom != null || widget.initialTo != null) {
      _from = widget.initialFrom;
      _to = widget.initialTo;
      _quick = widget.initialQuick ?? 'Custom';
      _applyFilters();
    } else if (widget.initialQuick != null) {
      _setQuick(widget.initialQuick!);
    }
  }

  void _applyFilters() {
    billController.filterBills(searchQuery: _searchCtrl.text, from: _from, to: _to);
  }

  void _setQuick(String label) {
    final now = DateTime.now();
    DateTime start;
    DateTime end;
    switch (label) {
      case 'Today':
        start = DateTime(now.year, now.month, now.day);
        end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        _from = start; _to = end; break;
      case 'Yesterday':
        final y = now.subtract(const Duration(days: 1));
        start = DateTime(y.year, y.month, y.day);
        end = DateTime(y.year, y.month, y.day, 23, 59, 59, 999);
        _from = start; _to = end; break;
      case 'This Week':
        final weekday = now.weekday; // 1 Mon ... 7 Sun
        start = DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
        end = start.add(const Duration(days: 6));
        end = DateTime(end.year, end.month, end.day, 23, 59, 59, 999);
        _from = start; _to = end; break;
      case 'This Month':
        start = DateTime(now.year, now.month, 1);
        end = DateTime(now.year, now.month + 1, 1).subtract(const Duration(milliseconds: 1));
        _from = start; _to = end; break;
      default:
        _from = null; _to = null; break;
    }
    setState(() { _quick = label; });
    _applyFilters();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: (_from != null && _to != null) ? DateTimeRange(start: _from!, end: _to!) : null,
    );
    if (range != null) {
      setState(() {
        _from = DateTime(range.start.year, range.start.month, range.start.day);
        _to = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59, 999);
        _quick = 'Custom';
      });
      _applyFilters();
    }
  }

  Future<void> _pickSingleDay() async {
    final now = DateTime.now();
    final day = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (day != null) {
      setState(() {
        _from = DateTime(day.year, day.month, day.day);
        _to = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);
        _quick = 'Day';
      });
      _applyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bill History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search by Bill ID or Customer Name',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _applyFilters(),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('All'),
                      _chip('Today'),
                      _chip('Yesterday'),
                      _chip('This Week'),
                      _chip('This Month'),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _pickRange,
                        icon: const Icon(Icons.date_range),
                        label: const Text('Date Range'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _pickSingleDay,
                        icon: const Icon(Icons.event),
                        label: const Text('Single Day'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
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
          ),
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

  Widget _chip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: _quick == label,
        onSelected: (_) => _setQuick(label),
      ),
    );
  }
}


