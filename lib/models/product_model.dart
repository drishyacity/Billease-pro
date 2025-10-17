import 'package:get/get.dart';

class ProductBatch {
  final String id;
  final String name;
  final double costPrice;
  final double sellingPrice;
  final double mrp;
  final DateTime? expiryDate;
  final double stock;

  ProductBatch({
    required this.id,
    required this.name,
    required this.costPrice,
    required this.sellingPrice,
    required this.mrp,
    this.expiryDate,
    required this.stock,
  });

  factory ProductBatch.fromJson(Map<String, dynamic> json) {
    return ProductBatch(
      id: json['id'],
      name: json['name'],
      costPrice: json['costPrice'],
      sellingPrice: json['sellingPrice'],
      mrp: json['mrp'],
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      stock: (json['stock'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'mrp': mrp,
      'expiryDate': expiryDate?.toIso8601String(),
      'stock': stock,
    };
  }
}

class UnitConversion {
  final String baseUnit; // e.g., piece
  final String convertedUnit; // e.g., box
  final double conversionFactor; // e.g., 12 (1 box = 12 piece)

  UnitConversion({
    required this.baseUnit,
    required this.convertedUnit,
    required this.conversionFactor,
  });

  factory UnitConversion.fromJson(Map<String, dynamic> json) {
    return UnitConversion(
      baseUnit: json['baseUnit'] as String,
      convertedUnit: json['convertedUnit'] as String,
      conversionFactor: (json['conversionFactor'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'baseUnit': baseUnit,
      'convertedUnit': convertedUnit,
      'conversionFactor': conversionFactor,
    };
  }
}

class Product {
  final String id;
  final String name;
  final String? barcode;
  final String? category;
  final String primaryUnit; // custom unit name
  final List<UnitConversion> unitConversions;
  final List<ProductBatch> batches;
  final double gstPercentage;
  final double cgstPercentage;
  final double sgstPercentage;
  final double discountPercentage;
  final int lowStockAlert;
  final int expiryAlertDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    this.barcode,
    this.category,
    required this.primaryUnit,
    this.unitConversions = const [],
    required this.batches,
    this.gstPercentage = 0.0,
    this.cgstPercentage = 0.0,
    this.sgstPercentage = 0.0,
    this.discountPercentage = 0.0,
    this.lowStockAlert = 10,
    this.expiryAlertDays = 30,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      barcode: json['barcode'],
      category: json['category'],
      primaryUnit: (json['primaryUnit'] ?? json['primary_unit']) as String,
      unitConversions: (json['unitConversions'] as List?)
          ?.map((e) => UnitConversion.fromJson(e))
          .toList() ??
          [],
      batches: (json['batches'] as List)
          .map((e) => ProductBatch.fromJson(e))
          .toList(),
      gstPercentage: json['gstPercentage'] ?? 0.0,
      cgstPercentage: json['cgstPercentage'] ?? 0.0,
      sgstPercentage: json['sgstPercentage'] ?? 0.0,
      discountPercentage: json['discountPercentage'] ?? 0.0,
      lowStockAlert: json['lowStockAlert'] ?? 10,
      expiryAlertDays: json['expiryAlertDays'] ?? 30,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'category': category,
      'primaryUnit': primaryUnit,
      'unitConversions': unitConversions.map((e) => e.toJson()).toList(),
      'batches': batches.map((e) => e.toJson()).toList(),
      'gstPercentage': gstPercentage,
      'cgstPercentage': cgstPercentage,
      'sgstPercentage': sgstPercentage,
      'discountPercentage': discountPercentage,
      'lowStockAlert': lowStockAlert,
      'expiryAlertDays': expiryAlertDays,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  double get totalStock {
    return batches.fold(0.0, (sum, batch) => sum + batch.stock);
  }

  bool get isLowStock {
    return totalStock <= lowStockAlert;
  }

  bool hasNearExpiryBatches() {
    final now = DateTime.now();
    return batches.any((batch) {
      if (batch.expiryDate == null) return false;
      final daysToExpiry = batch.expiryDate!.difference(now).inDays;
      return daysToExpiry <= expiryAlertDays && daysToExpiry > 0;
    });
  }

  bool hasExpiredBatches() {
    final now = DateTime.now();
    return batches.any((batch) {
      if (batch.expiryDate == null) return false;
      return batch.expiryDate!.isBefore(now);
    });
  }
}