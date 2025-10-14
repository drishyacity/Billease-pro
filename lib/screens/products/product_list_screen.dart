import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/product_controller.dart';
import '../../models/product_model.dart';
import 'product_detail_screen.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatelessWidget {
  final ProductController productController = Get.find<ProductController>();

  ProductListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _showExportDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload),
            onPressed: () => _showImportDialog(context),
          ),
        ],
      ),
      body: Obx(() {
        if (productController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (productController.filteredProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No products found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  productController.products.isEmpty
                      ? 'Add your first product to get started'
                      : 'Try adjusting your search or filters',
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                if (productController.products.isEmpty)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                    onPressed: () => Get.to(ProductFormScreen(product: null)),
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
                  hintText: 'Search products...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: productController.filterProducts,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: productController.filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = productController.filteredProducts[index];
                  return ProductListItem(product: product);
                },
              ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => ProductFormScreen(product: null)),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    String? selectedCategory;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Products'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Obx(() {
              final categories = ['All'] + productController.categories;
              return Wrap(
                spacing: 8,
                children: categories.map((category) {
                  final isSelected = category == 'All'
                      ? productController.categoryFilter.value.isEmpty
                      : productController.categoryFilter.value == category;
                  
                  return ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        selectedCategory = category == 'All' ? null : category;
                      }
                    },
                  );
                }).toList(),
              );
            }),
            const SizedBox(height: 16),
            const Text('Stock Status', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Obx(() => Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Low Stock'),
                      selected: productController.lowStockOnly.value,
                      onSelected: (selected) {
                        productController.setStockExpiryFilters(lowStock: selected);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Near Expiry'),
                      selected: productController.nearExpiryOnly.value,
                      onSelected: (selected) {
                        productController.setStockExpiryFilters(nearExpiry: selected);
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Expired'),
                      selected: productController.expiredOnly.value,
                      onSelected: (selected) {
                        productController.setStockExpiryFilters(expired: selected);
                      },
                    ),
                  ],
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (selectedCategory != null) {
                productController.setCategoryFilter(
                  selectedCategory == 'All' ? '' : selectedCategory!,
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Products'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              onTap: () {
                // Implement PDF export
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting as PDF...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as Excel'),
              onTap: () {
                // Implement Excel export
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting as Excel...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Products'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Import products from Excel file. The file should have the following columns:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Name, Barcode, Category, Unit, Cost Price, Selling Price, MRP, Stock, Expiry Date',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Select File'),
              onPressed: () {
                // Implement file selection
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File import functionality will be implemented soon')),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class ProductListItem extends StatelessWidget {
  final Product product;

  const ProductListItem({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final totalStock = product.totalStock;
    final isLowStock = product.isLowStock;
    final hasNearExpiry = product.hasNearExpiryBatches();
    final hasExpired = product.hasExpiredBatches();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => Get.to(() => ProductDetailScreen(product: product)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (product.category != null)
                    Chip(
                      label: Text(
                        product.category!,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.blue.shade100,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (product.barcode != null)
                Text(
                  'Barcode: ${product.barcode}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'MRP: ₹${product.batches.isNotEmpty ? product.batches.first.mrp.toStringAsFixed(2) : "N/A"}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Stock: $totalStock ${product.primaryUnit}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isLowStock ? Colors.red : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (isLowStock)
                    _buildStatusChip('Low Stock', Colors.red),
                  if (hasNearExpiry)
                    _buildStatusChip('Near Expiry', Colors.orange),
                  if (hasExpired)
                    _buildStatusChip('Expired', Colors.red.shade900),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: color,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class ProductSearchDelegate extends SearchDelegate<String> {
  final ProductController productController;

  ProductSearchDelegate(this.productController);

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
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    productController.filterProducts(query);
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Search by name, barcode, or ID',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    productController.filterProducts(query);
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return Obx(() {
      final results = productController.filteredProducts;
      
      if (results.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'No products found for "$query"',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      }
      
      return ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final product = results[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Text(product.barcode ?? 'No barcode'),
            trailing: Text(
              'Stock: ${product.totalStock}',
              style: TextStyle(
                color: product.isLowStock ? Colors.red : Colors.black,
              ),
            ),
            onTap: () {
              close(context, product.id);
              Get.to(() => ProductDetailScreen(product: product));
            },
          );
        },
      );
    });
  }
}