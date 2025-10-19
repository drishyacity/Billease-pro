import 'package:get/get.dart';
import '../models/supplier_model.dart';
import '../services/database_service.dart';

class SupplierController extends GetxController {
  final RxList<Supplier> _suppliers = <Supplier>[].obs;
  final RxList<Supplier> _filtered = <Supplier>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;

  List<Supplier> get suppliers => _suppliers;
  List<Supplier> get filteredSuppliers => _filtered;

  @override
  void onInit() {
    super.onInit();
    loadSuppliers();
  }

  Future<void> loadSuppliers() async {
    isLoading.value = true;
    try {
      final rows = await DatabaseService().getAllSuppliers();
      _suppliers.value = rows.map((e) => Supplier.fromJson(e)).toList();
      _filtered.value = _suppliers.toList();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addSupplier(Supplier supplier) async {
    final existing = await DatabaseService().findSupplierByPhoneOrName(phone: supplier.phone, name: supplier.name);
    if (existing != null) {
      Get.snackbar('Duplicate', 'Supplier already exists', snackPosition: SnackPosition.TOP);
      return;
    }
    await DatabaseService().upsertSupplier(supplier.toJson());
    _suppliers.add(supplier);
    filter(searchQuery.value);
  }

  Future<void> updateSupplier(Supplier supplier) async {
    final existing = await DatabaseService().findSupplierByPhoneOrName(phone: supplier.phone, name: supplier.name);
    if (existing != null && existing['id'] != supplier.id) {
      Get.snackbar('Duplicate', 'Another supplier with same name/phone exists', snackPosition: SnackPosition.TOP);
      return;
    }
    await DatabaseService().upsertSupplier(supplier.toJson());
    final idx = _suppliers.indexWhere((s) => s.id == supplier.id);
    if (idx != -1) {
      _suppliers[idx] = supplier;
      filter(searchQuery.value);
    }
  }

  Future<void> deleteSupplier(String id) async {
    await DatabaseService().deleteSupplierById(id);
    _suppliers.removeWhere((s) => s.id == id);
    filter(searchQuery.value);
  }

  void filter(String q) {
    searchQuery.value = q;
    if (q.isEmpty) {
      _filtered.value = _suppliers.toList();
    } else {
      final lq = q.toLowerCase();
      _filtered.value = _suppliers.where((s) {
        return s.name.toLowerCase().contains(lq) || s.phone.contains(q) || (s.email?.toLowerCase().contains(lq) ?? false) || s.id.toLowerCase().contains(lq);
      }).toList();
    }
  }
}
