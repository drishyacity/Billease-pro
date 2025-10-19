import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:billease_pro/screens/windows/windows_dashboard_screen.dart';
import 'package:billease_pro/screens/windows/windows_customers_screen.dart';
import 'package:billease_pro/screens/windows/windows_products_screen.dart';
import 'package:billease_pro/screens/windows/windows_suppliers_screen.dart';
import 'package:billease_pro/screens/windows/windows_billing_screen.dart';
import 'package:billease_pro/screens/windows/windows_bills_screen.dart';
import 'package:billease_pro/screens/windows/windows_reports_screen.dart';
import 'package:billease_pro/screens/windows/windows_settings_screen.dart';

class WindowsShell extends StatefulWidget {
  const WindowsShell({super.key});

  @override
  State<WindowsShell> createState() => _WindowsShellState();
}

class _WindowsShellState extends State<WindowsShell> {
  int _index = 0;

  final List<NavigationDestination> _destinations = const [
    NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
    NavigationDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt), label: 'Customers'),
    NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'Suppliers'),
    NavigationDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: 'Products'),
    NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Billing'),
    NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Bills'),
    NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Reports'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
  ];

  Widget _buildBody(int index) {
    switch (index) {
      case 0:
        return const WindowsDashboardScreen();
      case 1:
        return const WindowsCustomersScreen();
      case 2:
        return const WindowsSuppliersScreen();
      case 3:
        return const WindowsProductsScreen();
      case 4:
        return const WindowsBillingScreen();
      case 5:
        return const WindowsBillsScreen();
      case 6:
        return const WindowsReportsScreen();
      case 7:
        return const WindowsSettingsScreen();
      default:
        return const WindowsDashboardScreen();
    }
  }

  void _openCommandPalette() async {
    final commands = [
      ('Dashboard', Icons.dashboard, 0),
      ('Customers', Icons.people_alt, 1),
      ('Suppliers', Icons.local_shipping, 2),
      ('Products', Icons.inventory_2, 3),
      ('Billing', Icons.receipt_long, 4),
      ('Bills', Icons.history, 5),
      ('Reports', Icons.analytics, 6),
      ('Settings', Icons.settings, 7),
    ];
    await showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 200, vertical: 100),
          child: SizedBox(
            height: 420,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Type a command or page... (Esc to close)'
                    ),
                    onSubmitted: (_) {},
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: StatefulBuilder(builder: (context, setS) {
                    final q = controller.text.trim().toLowerCase();
                    final filtered = q.isEmpty
                        ? commands
                        : commands.where((c) => c.$1.toLowerCase().contains(q)).toList();
                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final (label, icon, idx) = filtered[i];
                        return ListTile(
                          leading: Icon(icon),
                          title: Text(label),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() => _index = idx);
                          },
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(Platform.isWindows, 'WindowsShell should only be used on Windows');
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK): ActivateIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (intent) {
            _openCommandPalette();
            return null;
          }),
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('BillEase Pro'),
            actions: [
              IconButton(
                tooltip: 'Command Palette (Ctrl+K)',
                icon: const Icon(Icons.search),
                onPressed: _openCommandPalette,
              ),
            ],
          ),
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                labelType: NavigationRailLabelType.selected,
                leading: const SizedBox(height: 8),
                destinations: const [
                  NavigationRailDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: Text('Dashboard')),
                  NavigationRailDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt), label: Text('Customers')),
                  NavigationRailDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: Text('Suppliers')),
                  NavigationRailDestination(icon: Icon(Icons.inventory_2_outlined), selectedIcon: Icon(Icons.inventory_2), label: Text('Products')),
                  NavigationRailDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: Text('Billing')),
                  NavigationRailDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: Text('Bills')),
                  NavigationRailDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: Text('Reports')),
                  NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _buildBody(_index),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
