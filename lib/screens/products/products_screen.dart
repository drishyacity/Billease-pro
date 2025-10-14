import 'package:flutter/material.dart';
import 'package:billease_pro/constants/app_constants.dart';
import 'package:billease_pro/models/product_model.dart';
import 'package:billease_pro/models/category_model.dart';
import 'package:billease_pro/models/unit_model.dart';
import 'package:billease_pro/services/database_service.dart';
import 'package:billease_pro/utils/theme.dart';
import 'package:billease_pro/screens/products/categories_screen.dart';
import 'package:billease_pro/screens/products/units_screen.dart';
import 'package:intl/intl.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  int? _selectedCategoryId;
  final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = await _databaseService.database;
      
      // Load categories
      final List<Map<String, dynamic>> categoryMaps = await db.query(
        'categories',
        orderBy: 'name ASC',
      );
      
      _categories = List.generate(categoryMaps.length, (i) {
        return Category.fromMap(categoryMaps[i]);
      });

      // Load products with their categories and base units
      final List<Map<String, dynamic>> productMaps = await db.query('products');
      
      _products = [];
      
      for (var productMap in productMaps) {
        final product = Product.fromMap(productMap);
        
        // Get category
        final List<Map<String, dynamic>> categoryMaps = await db.query(
          'categories',
          where: 'id = ?',
          whereArgs: [product.categoryId],
        );
        
        if (categoryMaps.isNotEmpty) {
          product.category = Category.fromMap(categoryMaps.first);
        }
        
        // Get base unit
        final List<Map<String, dynamic>> unitMaps = await db.query(
          'units',
          where: 'id = ?',
          whereArgs: [product.baseUnitId],
        );
        
        if (unitMaps.isNotEmpty) {
          product.baseUnit = Unit.fromMap(unitMaps.first);
        }
        
        // Get batches
        final List<Map<String, dynamic>> batchMaps = await db.query(
          'product_batches',
          where: 'product_id = ?',
          whereArgs: [product.id],
        );
        
        product.batches = List.generate(batchMaps.length, (i) {
          return ProductBatch.fromMap(batchMaps[i]);
        });
        
        _products.add(product);
      }

      setState(() {
        _filteredProducts = _products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading products: ${e.toString()}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isEmpty && _selectedCategoryId == null) {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products.where((product) {
          bool matchesQuery = query.isEmpty || 
              product.name.toLowerCase().contains(query.toLowerCase()) ||
              (product.barcode != null && product.barcode!.contains(query));
          
          bool matchesCategory = _selectedCategoryId == null || 
              product.categoryId == _selectedCategoryId;
          
          return matchesQuery && matchesCategory;
        }).toList();
      }
    });
  }

  void _filterByCategory(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _filterProducts(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CategoriesScreen(),
                ),
              ).then((_) => _loadData());
            },
            tooltip: 'Manage Categories',
          ),
          IconButton(
            icon: const Icon(Icons.straighten),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UnitsScreen(),
                ),
              ).then((_) => _loadData());
            },
            tooltip: 'Manage Units',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or barcode',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterProducts('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: _filterProducts,
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Categories'),
                        selected: _selectedCategoryId == null,
                        onSelected: (selected) {
                          if (selected) {
                            _filterByCategory(null);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ..._categories.map((category) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            label: Text(category.name),
                            selected: _selectedCategoryId == category.id,
                            onSelected: (selected) {
                              if (selected) {
                                _filterByCategory(category.id);
                              } else {
                                _filterByCategory(null);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: AppTheme.textSecondaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isNotEmpty || _selectedCategoryId != null
                                  ? 'No products found'
                                  : 'No products yet',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchController.text.isNotEmpty || _selectedCategoryId != null
                                  ? 'Try a different search term or category'
                                  : 'Add your first product',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          return _buildProductCard(product);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditProductScreen(categories: _categories),
            ),
          ).then((_) => _loadData());
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    // Calculate total stock across all batches
    double totalStock = 0;
    if (product.batches != null && product.batches!.isNotEmpty) {
      totalStock = product.batches!.fold(0, (sum, batch) => sum + batch.stock);
    }

    // Get the latest batch for price display
    ProductBatch? latestBatch;
    if (product.batches != null && product.batches!.isNotEmpty) {
      latestBatch = product.batches!.reduce((a, b) => 
        a.createdAt.isAfter(b.createdAt) ? a : b);
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(productId: product.id!),
            ),
          ).then((_) => _loadData());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      product.name.isNotEmpty ? product.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.category?.name ?? 'Unknown Category',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditProductScreen(
                            product: product,
                            categories: _categories,
                          ),
                        ),
                      ).then((_) => _loadData());
                    },
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoColumn(
                    'Stock',
                    '${totalStock.toStringAsFixed(2)} ${product.baseUnit?.shortName ?? product.baseUnit?.name ?? ''}',
                    Icons.inventory,
                    textColor: totalStock <= (product.lowStockAlert ?? 0) ? AppTheme.errorColor : null,
                  ),
                  _buildInfoColumn(
                    'Selling Price',
                    latestBatch != null ? currencyFormat.format(latestBatch.sellingPrice) : 'N/A',
                    Icons.sell,
                  ),
                  _buildInfoColumn(
                    'MRP',
                    latestBatch != null ? currencyFormat.format(latestBatch.mrp) : 'N/A',
                    Icons.price_change,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, IconData icon, {Color? textColor}) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.textSecondaryColor,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
        ),
      ],
    );
  }
}