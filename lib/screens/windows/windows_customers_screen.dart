import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:billease_pro/controllers/customer_controller.dart';
import 'package:billease_pro/controllers/bill_controller.dart';
import 'package:billease_pro/models/customer_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

class WindowsCustomersScreen extends StatefulWidget {
  const WindowsCustomersScreen({super.key});

  @override
  State<WindowsCustomersScreen> createState() => _WindowsCustomersScreenState();
}

class _WindowsCustomersScreenState extends State<WindowsCustomersScreen> {
  final CustomerController controller = Get.find<CustomerController>();
  final BillController billController = Get.find<BillController>();
  final TextEditingController _searchCtrl = TextEditingController();
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _addOrEditCustomer({Customer? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    final addrCtrl = TextEditingController(text: existing?.address ?? '');
    final gstCtrl = TextEditingController(text: existing?.gstin ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add Customer' : 'Edit Customer'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address')),
              TextField(controller: gstCtrl, decoration: const InputDecoration(labelText: 'GSTIN')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (result == true) {
      if (existing == null) {
        final now = DateTime.now();
        final c = Customer(
          id: const Uuid().v4(),
          name: nameCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
          address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
          gstin: gstCtrl.text.trim().isEmpty ? null : gstCtrl.text.trim(),
          createdAt: now,
          updatedAt: now,
        );
        await controller.addCustomer(c);
      } else {
        final now = DateTime.now();
        final c = Customer(
          id: existing.id,
          name: nameCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
          address: addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
          gstin: gstCtrl.text.trim().isEmpty ? null : gstCtrl.text.trim(),
          totalPurchases: existing.totalPurchases,
          dueAmount: existing.dueAmount,
          createdAt: existing.createdAt,
          updatedAt: now,
        );
        await controller.updateCustomer(c);
      }
      setState(() {});
    }
  }

  DateTime? _lastPurchaseFor(String customerId) {
    final bills = billController.bills.where((b) => b.customerId == customerId);
    if (bills.isEmpty) return null;
    return bills.map((b) => b.date).reduce((a, b) => a.isAfter(b) ? a : b);
  }

  void _launchTel(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Customers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              SizedBox(
                width: 280,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search customers'),
                  onChanged: (v) => setState(() => controller.filterCustomers(v)),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(onPressed: () => _addOrEditCustomer(), icon: const Icon(Icons.person_add), label: const Text('Add')),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              final items = controller.filteredCustomers.isNotEmpty || _searchCtrl.text.isNotEmpty
                  ? controller.filteredCustomers
                  : controller.customers;
              return Card(
                clipBehavior: Clip.antiAlias,
                child: PaginatedDataTable(
                  header: const Text('Customers'),
                  rowsPerPage: _rowsPerPage,
                  availableRowsPerPage: const [10, 25, 50, 100],
                  onRowsPerPageChanged: (v) => setState(() => _rowsPerPage = v ?? _rowsPerPage),
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Phone')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Due')),
                    DataColumn(label: Text('Last Purchase')),
                    DataColumn(label: Text('Actions')),
                  ],
                  source: _CustomersSource(
                    items: items,
                    lastPurchaseFor: _lastPurchaseFor,
                    onEdit: (c) => _addOrEditCustomer(existing: c),
                    onCall: (p) => _launchTel(p),
                    onEmail: (e) => _launchEmail(e),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CustomersSource extends DataTableSource {
  final List<Customer> items;
  final DateTime? Function(String customerId) lastPurchaseFor;
  final void Function(Customer c) onEdit;
  final void Function(String phone) onCall;
  final void Function(String email) onEmail;

  _CustomersSource({
    required this.items,
    required this.lastPurchaseFor,
    required this.onEdit,
    required this.onCall,
    required this.onEmail,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= items.length) return null;
    final c = items[index];
    final last = lastPurchaseFor(c.id);
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(Text(c.name)),
        DataCell(Row(children: [Text(c.phone), const SizedBox(width: 8), IconButton(icon: const Icon(Icons.call), tooltip: 'Call', onPressed: () => onCall(c.phone))])),
        DataCell(Row(children: [Text(c.email ?? '-'), if ((c.email ?? '').isNotEmpty) ...[const SizedBox(width: 8), IconButton(icon: const Icon(Icons.email_outlined), tooltip: 'Email', onPressed: () => onEmail(c.email!))]])),
        DataCell(Text('₹${c.dueAmount.toStringAsFixed(2)}')),
        DataCell(Text(last == null ? '-' : '${last.day}/${last.month}/${last.year}')),
        DataCell(Row(children: [
          IconButton(icon: const Icon(Icons.edit_outlined), tooltip: 'Edit', onPressed: () => onEdit(c)),
        ])),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => items.length;

  @override
  int get selectedRowCount => 0;
}
