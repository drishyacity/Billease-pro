import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/customer_controller.dart';
import '../../models/customer_model.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../products/product_list_screen.dart';
import '../billing/billing_screen.dart';

class CustomerListScreen extends StatelessWidget {
  const CustomerListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final CustomerController customerController = Get.find<CustomerController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: const [],
      ),
      body: Obx(() {
        if (customerController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (customerController.customers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.people_outline, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No customers yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Add your first customer to get started'),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Customer'),
                  onPressed: () => _navigateToCustomerForm(context),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search customers...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: customerController.filterCustomers,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: customerController.filteredCustomers.length,
                itemBuilder: (context, index) {
                  final customer = customerController.filteredCustomers[index];
                  return _buildCustomerListItem(context, customer);
                },
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final before = customerController.customers.length;
          await Get.to(() => const CustomerFormScreen());
          // ensure reload after returning in case list stayed loading
          if (customerController.customers.length == before) {
            customerController.loadCustomers();
          }
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Get.offAll(() => const DashboardScreen());
              break;
            case 1:
              // Already on Customers
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

  Widget _buildCustomerListItem(BuildContext context, Customer customer) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Phone: ${customer.phone}'),
            if (customer.dueAmount > 0)
              Text(
                'Due: ₹${customer.dueAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Total: ₹${customer.totalPurchases.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${customer.id}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        onTap: () {
          Get.to(() => CustomerDetailScreen(customer: customer));
        },
      ),
    );
  }

  void _navigateToCustomerForm(BuildContext context) {
    Get.to(() => const CustomerFormScreen());
  }
}

class CustomerSearchDelegate extends SearchDelegate {
  final CustomerController customerController;

  CustomerSearchDelegate(this.customerController);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    customerController.filterCustomers(query);
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    customerController.filterCustomers(query);
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return Obx(() {
      final customers = customerController.filteredCustomers;
      
      if (customers.isEmpty) {
        return const Center(
          child: Text('No customers found'),
        );
      }
      
      return ListView.builder(
        itemCount: customers.length,
        itemBuilder: (context, index) {
          final customer = customers[index];
          return ListTile(
            title: Text(customer.name),
            subtitle: Text(customer.phone),
            onTap: () {
              Get.to(() => CustomerDetailScreen(customer: customer));
              close(context, null);
            },
          );
        },
      );
    });
  }
}