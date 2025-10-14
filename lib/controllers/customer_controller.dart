import 'package:get/get.dart';
import '../models/customer_model.dart';
import '../services/database_service.dart';

class CustomerController extends GetxController {
  final RxList<Customer> _customers = <Customer>[].obs;
  final RxList<Customer> _filteredCustomers = <Customer>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  List<Customer> get customers => _customers;
  List<Customer> get filteredCustomers => _filteredCustomers;

  @override
  void onInit() {
    super.onInit();
    loadCustomers();
  }

  void loadCustomers() async {
    isLoading.value = true;
    try {
      final db = DatabaseService();
      final rows = await db.getAllCustomers();
      _customers.value = rows.map((e) => Customer.fromJson(e)).toList();
      _filteredCustomers.value = _customers.toList();
    } catch (e) {
      // In case of any failure, keep lists consistent and continue
      _customers.clear();
      _filteredCustomers.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addCustomer(Customer customer) async {
    await DatabaseService().upsertCustomer(customer.toJson());
    _customers.add(customer);
    filterCustomers(searchQuery.value);
  }

  Future<void> updateCustomer(Customer updatedCustomer) async {
    await DatabaseService().upsertCustomer(updatedCustomer.toJson());
    final index = _customers.indexWhere((c) => c.id == updatedCustomer.id);
    if (index != -1) {
      _customers[index] = updatedCustomer;
      filterCustomers(searchQuery.value);
    }
  }

  void deleteCustomer(String id) {
    _customers.removeWhere((c) => c.id == id);
    filterCustomers(searchQuery.value);
  }

  void filterCustomers(String query) {
    searchQuery.value = query;
    if (query.isEmpty) {
      _filteredCustomers.value = _customers.toList();
    } else {
      _filteredCustomers.value = _customers.where((customer) {
        return customer.name.toLowerCase().contains(query.toLowerCase()) ||
            customer.phone.contains(query) ||
            (customer.email != null && customer.email!.toLowerCase().contains(query.toLowerCase())) ||
            customer.id.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
  }
}