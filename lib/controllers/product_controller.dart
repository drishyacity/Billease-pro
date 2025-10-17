import 'package:get/get.dart';
import '../models/product_model.dart';
import '../services/database_service.dart';

class ProductController extends GetxController {
  final RxList<Product> _products = <Product>[].obs;
  final RxList<Product> _filteredProducts = <Product>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final RxString searchQuery = ''.obs;
  final RxString categoryFilter = ''.obs;
  final RxSet<String> selectedCategories = <String>{}.obs;
  final RxBool lowStockOnly = false.obs;
  final RxBool nearExpiryOnly = false.obs;
  final RxBool expiredOnly = false.obs;
  final RxnInt nearExpiryWithinDays = RxnInt(null);
  final RxnInt nearExpiryMonth = RxnInt(null); // 1-12
  final RxnInt nearExpiryYear = RxnInt(null);

  final int _pageSize = 200;
  int _offset = 0;

  RxList<Product> get products => _products;
  RxList<Product> get filteredProducts => _filteredProducts;

  @override
  void onInit() {
    super.onInit();
    loadInitialProducts();
  }

  Future<void> loadProducts() async {
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

  Future<void> loadInitialProducts() async {
    isLoading.value = true;
    hasMore.value = true;
    _offset = 0;
    try {
      final db = DatabaseService();
      final rows = await db.getProductsWithRelationsPage(limit: _pageSize, offset: _offset);
      final items = rows.map((e) => Product.fromJson(e)).toList();
      _products
        ..clear()
        ..addAll(items);
      _offset += items.length;
      hasMore.value = items.length == _pageSize;
      _applyFilters();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMoreProducts() async {
    if (isLoadingMore.value || !hasMore.value) return;
    isLoadingMore.value = true;
    try {
      final db = DatabaseService();
      final rows = await db.getProductsWithRelationsPage(limit: _pageSize, offset: _offset);
      final items = rows.map((e) => Product.fromJson(e)).toList();
      _products.addAll(items);
      _offset += items.length;
      if (items.length < _pageSize) {
        hasMore.value = false;
      }
      _applyFilters();
    } finally {
      isLoadingMore.value = false;
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

  Future<void> deleteProduct(String id) async {
    await DatabaseService().deleteProductById(id);
    _products.removeWhere((p) => p.id == id);
    filterProducts(searchQuery.value);
  }

  void filterProducts(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void setCategoryFilter(String category) {
    categoryFilter.value = category;
    _applyFilters();
  }

  void toggleCategorySelection(String category, bool selected) {
    if (selected) {
      selectedCategories.add(category);
    } else {
      selectedCategories.remove(category);
    }
    _applyFilters();
  }

  void clearCategorySelections() {
    selectedCategories.clear();
    _applyFilters();
  }

  void setStockExpiryFilters({bool? lowStock, bool? nearExpiry, bool? expired}) {
    if (lowStock != null) lowStockOnly.value = lowStock;
    if (nearExpiry != null) nearExpiryOnly.value = nearExpiry;
    if (expired != null) expiredOnly.value = expired;
    _applyFilters();
  }

  void setNearExpiryWithinDays(int? days) {
    nearExpiryWithinDays.value = days;
    _applyFilters();
  }

  void setNearExpiryMonthYear({int? month, int? year}) {
    nearExpiryMonth.value = month;
    nearExpiryYear.value = year;
    _applyFilters();
  }

  void clearNearExpiryFilters() {
    nearExpiryWithinDays.value = null;
    nearExpiryMonth.value = null;
    nearExpiryYear.value = null;
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
    if (selectedCategories.isNotEmpty) {
      filtered = filtered.where((product) => product.category != null && selectedCategories.contains(product.category!)).toList();
    } else if (categoryFilter.value.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.category == categoryFilter.value;
      }).toList();
    }
    
    // Stock/expiry filters
    if (lowStockOnly.value) {
      filtered = filtered.where((p) => p.isLowStock).toList();
    }
    if (nearExpiryOnly.value) {
      if (nearExpiryMonth.value != null && nearExpiryYear.value != null) {
        filtered = filtered.where((p) {
          return p.batches.any((b) {
            if (b.expiryDate == null) return false;
            final e = b.expiryDate!;
            return e.year == nearExpiryYear.value && e.month == nearExpiryMonth.value;
          });
        }).toList();
      } else if (nearExpiryWithinDays.value == null) {
        filtered = filtered.where((p) => p.hasNearExpiryBatches()).toList();
      } else {
        final now = DateTime.now();
        final maxDays = nearExpiryWithinDays.value!;
        filtered = filtered.where((p) {
          return p.batches.any((b) {
            if (b.expiryDate == null) return false;
            final d = b.expiryDate!.difference(now).inDays;
            return d >= 0 && d <= maxDays;
          });
        }).toList();
      }
    }
    if (expiredOnly.value) {
      filtered = filtered.where((p) => p.hasExpiredBatches()).toList();
    }

    // Sort alphabetically by product name
    filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _filteredProducts.value = filtered.toList();
  }

  bool get hasActiveFilters {
    return searchQuery.value.isNotEmpty || categoryFilter.value.isNotEmpty || selectedCategories.isNotEmpty || lowStockOnly.value || nearExpiryOnly.value || expiredOnly.value || nearExpiryWithinDays.value != null || nearExpiryMonth.value != null || nearExpiryYear.value != null;
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