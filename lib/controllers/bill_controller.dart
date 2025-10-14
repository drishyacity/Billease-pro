import 'package:get/get.dart';
import '../models/bill_model.dart';
import '../services/database_service.dart';

class BillController extends GetxController {
  final RxList<Bill> _bills = <Bill>[].obs;
  final RxList<Bill> _filteredBills = <Bill>[].obs;
  final RxBool _isLoading = false.obs;

  List<Bill> get bills => _bills;
  List<Bill> get filteredBills => _filteredBills;
  bool get isLoading => _isLoading.value;

  @override
  void onInit() {
    super.onInit();
    loadBills();
  }

  void filterBills({String? searchQuery}) {
    if (searchQuery == null || searchQuery.isEmpty) {
      _filteredBills.value = _bills;
    } else {
      _filteredBills.value = _bills.where((bill) => 
        bill.id.toLowerCase().contains(searchQuery.toLowerCase()) ||
        (bill.customerName != null && bill.customerName!.toLowerCase().contains(searchQuery.toLowerCase()))
      ).toList();
    }
  }

  Future<void> loadBills() async {
    _isLoading.value = true;
    try {
      final db = DatabaseService();
      final billRows = await db.getAllBills();
      final List<Bill> loaded = [];
      for (final row in billRows) {
        final items = await db.getBillItems(row['id'] as String);
        final bill = Bill.fromJson({
          ...row,
          'items': items,
          // adapt enum string format
          'type': row['type'],
          'status': row['status'],
        });
        loaded.add(bill);
      }
      _bills.value = loaded;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load bills: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _filteredBills.value = _bills;
      _isLoading.value = false;
    }
  }

  Future<void> addBill(Bill bill) async {
    _isLoading.value = true;
    try {
      final db = DatabaseService();
      await db.insertBill(bill.toJson(), bill.items.map((e) => e.toJson()..['bill_id'] = bill.id).toList());
      _bills.add(bill);
      _filteredBills.value = _bills;
      Get.snackbar(
        'Success',
        'Bill created successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create bill: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> updateBill(Bill bill) async {
    _isLoading.value = true;
    try {
      // Simulate updating in database
      await Future.delayed(const Duration(milliseconds: 500));
      final index = _bills.indexWhere((b) => b.id == bill.id);
      if (index != -1) {
        _bills[index] = bill;
        Get.snackbar(
          'Success',
          'Bill updated successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update bill: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteBill(String id) async {
    _isLoading.value = true;
    try {
      // Simulate deleting from database
      await Future.delayed(const Duration(milliseconds: 500));
      _bills.removeWhere((bill) => bill.id == id);
      Get.snackbar(
        'Success',
        'Bill deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete bill: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      _isLoading.value = false;
    }
  }
}