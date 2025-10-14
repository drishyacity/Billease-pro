import 'package:get/get.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';

class ProductController extends GetxController {
  final RxList<Product> _products = <Product>[].obs;
  final RxList<Product> _filteredProducts = <Product>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString categoryFilter = ''.obs;
  final RxBool lowStockOnly = false.obs;
  final RxBool nearExpiryOnly = false.obs;
  final RxBool expiredOnly = false.obs;

  RxList<Product> get products => _products;
  RxList<Product> get filteredProducts => _filteredProducts;

  @override
  void onInit() {
    super.onInit();
    loadProducts();
  }

  void loadProducts() async {
    isLoading.value = true;
    try {
      final db = DatabaseService();
      final rows = await db.getAllProductsWithRelations();
      _products.value = rows.map((e) => Product.fromJson(e)).toList();
      _applyFilters();
    } finally {
      isLoading.value = false;
    }
  }

  void addProduct(Product product) {
    _products.add(product);
    filterProducts(searchQuery.value);
  }

  void updateProduct(Product updatedProduct) {
    final index = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (index != -1) {
      _products[index] = updatedProduct;
      filterProducts(searchQuery.value);
    }
  }

  void deleteProduct(String id) {
    DatabaseService().deleteProductById(id).then((_) {
      _products.removeWhere((p) => p.id == id);
      filterProducts(searchQuery.value);
    });
  }

  void filterProducts(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void setCategoryFilter(String category) {
    categoryFilter.value = category;
    _applyFilters();
  }

  void setStockExpiryFilters({bool? lowStock, bool? nearExpiry, bool? expired}) {
    if (lowStock != null) lowStockOnly.value = lowStock;
    if (nearExpiry != null) nearExpiryOnly.value = nearExpiry;
    if (expired != null) expiredOnly.value = expired;
    _applyFilters();
  }

  void _applyFilters() {
    List<Product> filtered = _products.toList();
    
    // Apply search query filter
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
            (product.barcode != null && product.barcode!.contains(searchQuery.value)) ||
            product.id.toLowerCase().contains(searchQuery.value.toLowerCase());
      }).toList();
    }
    
    // Apply category filter
    if (categoryFilter.value.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.category == categoryFilter.value;
      }).toList();
    }
    
    // Stock/expiry filters
    if (lowStockOnly.value) {
      filtered = filtered.where((p) => p.isLowStock).toList();
    }
    if (nearExpiryOnly.value) {
      filtered = filtered.where((p) => p.hasNearExpiryBatches()).toList();
    }
    if (expiredOnly.value) {
      filtered = filtered.where((p) => p.hasExpiredBatches()).toList();
    }

    _filteredProducts.value = filtered.toList();
  }

  List<String> get categories {
    final categorySet = <String>{};
    for (final product in _products) {
      if (product.category != null && product.category!.isNotEmpty) {
        categorySet.add(product.category!);
      }
    }
    return categorySet.toList()..sort();
  }

  List<Product> getLowStockProducts() {
    return _products.where((product) => product.isLowStock).toList();
  }

  List<Product> getNearExpiryProducts() {
    return _products.where((product) => product.hasNearExpiryBatches()).toList();
  }

  List<Product> getExpiredProducts() {
    return _products.where((product) => product.hasExpiredBatches()).toList();
  }
}