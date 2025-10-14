import 'package:get/get.dart';

class Customer {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? gstin;
  final double totalPurchases;
  final double dueAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.gstin,
    this.totalPurchases = 0.0,
    this.dueAmount = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      address: json['address'],
      gstin: json['gstin'],
      totalPurchases: (json['totalPurchases'] ?? json['total_purchases'] ?? 0).toDouble(),
      dueAmount: (json['dueAmount'] ?? json['due_amount'] ?? 0).toDouble(),
      createdAt: DateTime.parse((json['createdAt'] ?? json['created_at']) as String),
      updatedAt: DateTime.parse((json['updatedAt'] ?? json['updated_at']) as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'gstin': gstin,
      'totalPurchases': totalPurchases,
      'dueAmount': dueAmount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}