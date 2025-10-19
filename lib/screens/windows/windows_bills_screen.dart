import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:billease_pro/screens/bills/bill_history_screen.dart';
import 'package:billease_pro/screens/bills/estimate_history_screen.dart';

class WindowsBillsScreen extends StatefulWidget {
  const WindowsBillsScreen({super.key});

  @override
  State<WindowsBillsScreen> createState() => _WindowsBillsScreenState();
}

class _WindowsBillsScreenState extends State<WindowsBillsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          TabBar(controller: _tab, tabs: const [Tab(text: 'Bills'), Tab(text: 'Estimates')]),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                BillHistoryScreen(),
                EstimateHistoryScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
