import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:billease_pro/controllers/bill_controller.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:typed_data';

class WindowsReportsScreen extends StatefulWidget {
  const WindowsReportsScreen({super.key});

  @override
  State<WindowsReportsScreen> createState() => _WindowsReportsScreenState();
}

class _WindowsReportsScreenState extends State<WindowsReportsScreen> {
  final BillController billController = Get.find<BillController>();
  DateTimeRange? _range;

  Iterable _filtered() {
    if (_range == null) return billController.bills;
    final start = DateTime(_range!.start.year, _range!.start.month, _range!.start.day);
    final end = DateTime(_range!.end.year, _range!.end.month, _range!.end.day, 23, 59, 59, 999);
    return billController.bills.where((b) => !b.date.isBefore(start) && !b.date.isAfter(end));
  }

  double _totalSales() {
    return _filtered().fold<double>(0.0, (sum, b) => sum + b.totalAmount);
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(context: context, firstDate: DateTime(2023, 1, 1), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (picked != null) setState(() => _range = picked);
  }

  Future<void> _exportCsv() async {
    final rows = StringBuffer('BillID,Date,Customer,Amount\n');
    for (final b in _filtered()) {
      rows.writeln('${b.id},${b.date.toIso8601String()},"${b.customerName ?? ''}",${b.totalAmount.toStringAsFixed(2)}');
    }
    rows.writeln('\nTotal, , ,${_totalSales().toStringAsFixed(2)}');
    final bytes = Uint8List.fromList(rows.toString().codeUnits);
    await FileSaver.instance.saveFile(name: 'reports_export', bytes: bytes, ext: 'csv', mimeType: MimeType.csv);
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered().toList();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              OutlinedButton.icon(onPressed: _pickRange, icon: const Icon(Icons.date_range), label: Text(_range == null ? 'Pick Date Range' : '${_range!.start.day}/${_range!.start.month}/${_range!.start.year} - ${_range!.end.day}/${_range!.end.month}/${_range!.end.year}')),
              const SizedBox(width: 8),
              OutlinedButton.icon(onPressed: _exportCsv, icon: const Icon(Icons.download), label: const Text('Export CSV')),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(child: _kpi('Total Bills', list.length.toString())),
                  Expanded(child: _kpi('Total Sales', '₹${_totalSales().toStringAsFixed(2)}')),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final b = list[i];
                  return ListTile(
                    title: Text('Bill #${b.id.substring(0, 8)}  •  ₹${b.totalAmount.toStringAsFixed(2)}'),
                    subtitle: Text('${b.date.day}/${b.date.month}/${b.date.year}  •  ${b.customerName ?? 'Customer'}'),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _kpi(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
