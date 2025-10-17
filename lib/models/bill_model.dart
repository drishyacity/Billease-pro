import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

enum BillType { quickSale, retail, wholesale }

enum BillStatus { draft, completed, partiallyPaid, fullyPaid }

class Bill {
  final String id;
  final DateTime date;
  final BillType type;
  final String? customerId;
  final String? customerName;
  final List<BillItem> items;
  final double totalAmount;
  final double paidAmount;
  final BillStatus status;
  final String? notes;
  final double finalDiscountValue;
  final bool finalDiscountIsPercent;
  final double extraAmount;
  final String? extraAmountName;
  final bool gstEnabled;
  final bool inlineGst;

  Bill({
    String? id,
    DateTime? date,
    required this.type,
    this.customerId,
    this.customerName,
    required this.items,
    required this.totalAmount,
    this.paidAmount = 0.0,
    this.status = BillStatus.draft,
    this.notes,
    this.finalDiscountValue = 0.0,
    this.finalDiscountIsPercent = true,
    this.extraAmount = 0.0,
    this.extraAmountName,
    this.gstEnabled = false,
    this.inlineGst = true,
  }) : 
    id = id ?? const Uuid().v4(),
    date = date ?? DateTime.now();

  Bill copyWith({
    String? id,
    DateTime? date,
    BillType? type,
    String? customerId,
    String? customerName,
    List<BillItem>? items,
    double? totalAmount,
    double? paidAmount,
    BillStatus? status,
    String? notes,
    double? finalDiscountValue,
    bool? finalDiscountIsPercent,
    double? extraAmount,
    String? extraAmountName,
    bool? gstEnabled,
    bool? inlineGst,
  }) {
    return Bill(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      finalDiscountValue: finalDiscountValue ?? this.finalDiscountValue,
      finalDiscountIsPercent: finalDiscountIsPercent ?? this.finalDiscountIsPercent,
      extraAmount: extraAmount ?? this.extraAmount,
      extraAmountName: extraAmountName ?? this.extraAmountName,
      gstEnabled: gstEnabled ?? this.gstEnabled,
      inlineGst: inlineGst ?? this.inlineGst,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type.toString(),
      'customerId': customerId,
      'customerName': customerName,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'status': status.toString(),
      'notes': notes,
      'finalDiscountValue': finalDiscountValue,
      'finalDiscountIsPercent': finalDiscountIsPercent,
      'extraAmount': extraAmount,
      'extraAmountName': extraAmountName,
      'gstEnabled': gstEnabled,
      'inlineGst': inlineGst,
    };
  }

  factory Bill.fromJson(Map<String, dynamic> json) {
    String typeRaw = json['type'];
    String statusRaw = json['status'];
    BillType resolvedType = BillType.retail;
    for (final e in BillType.values) {
      if (typeRaw == e.toString() || typeRaw == e.name) {
        resolvedType = e;
        break;
      }
    }
    BillStatus resolvedStatus = BillStatus.draft;
    for (final e in BillStatus.values) {
      if (statusRaw == e.toString() || statusRaw == e.name) {
        resolvedStatus = e;
        break;
      }
    }
    final num? totalNum = json['totalAmount'] as num?;
    final num? paidNum = json['paidAmount'] as num?;
    return Bill(
      id: json['id'],
      date: DateTime.parse(json['date']),
      type: resolvedType,
      customerId: json['customerId'],
      customerName: json['customerName'],
      items: (json['items'] as List?)?.map((item) => BillItem.fromJson(item)).toList() ?? const [],
      totalAmount: (totalNum)?.toDouble() ?? 0.0,
      paidAmount: (paidNum)?.toDouble() ?? 0.0,
      status: resolvedStatus,
      notes: json['notes'],
      finalDiscountValue: (json['finalDiscountValue'] as num?)?.toDouble() ?? 0.0,
      finalDiscountIsPercent: (json['finalDiscountIsPercent'] as bool?) ?? (json['final_discount_is_percent'] == 1),
      extraAmount: (json['extraAmount'] as num?)?.toDouble() ?? 0.0,
      extraAmountName: json['extraAmountName'],
      gstEnabled: (json['gstEnabled'] as bool?) ?? (json['gst_enabled'] == 1),
      inlineGst: (json['inlineGst'] as bool?) ?? (json['inline_gst'] != 0),
    );
  }
}

class BillItem {
  final String id;
  final String productId;
  final String productName;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final String? batchId;
  final String? unit; // e.g. piece, box
  final double? cgst; // percent
  final double? sgst; // percent
  final double? discountPercent; // percent
  // Per-bill overrides (do not affect product/batch in DB)
  final double? mrpOverride;
  final DateTime? expiryOverride;

  BillItem({
    String? id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    double? totalPrice,
    this.batchId,
    this.unit,
    this.cgst,
    this.sgst,
    this.discountPercent,
    this.mrpOverride,
    this.expiryOverride,
  }) : 
    id = id ?? const Uuid().v4(),
    totalPrice = totalPrice ?? (quantity * unitPrice);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'batch_id': batchId,
      'unit': unit,
      'cgst': cgst,
      'sgst': sgst,
      'discount_percent': discountPercent,
      'mrp_override': mrpOverride,
      'expiry_override': expiryOverride?.toIso8601String(),
    };
  }

  factory BillItem.fromJson(Map<String, dynamic> json) {
    final num? q = json['quantity'] as num?;
    final num? up = json['unitPrice'] as num?;
    final num? tp = json['totalPrice'] as num?;
    return BillItem(
      id: json['id'],
      productId: json['productId'],
      productName: json['productName'],
      quantity: (q)?.toDouble() ?? 0.0,
      unitPrice: (up)?.toDouble() ?? 0.0,
      totalPrice: (tp)?.toDouble(),
      batchId: json['batch_id'],
      unit: json['unit'],
      cgst: (json['cgst'] as num?)?.toDouble(),
      sgst: (json['sgst'] as num?)?.toDouble(),
      discountPercent: (json['discount_percent'] as num?)?.toDouble(),
      mrpOverride: (json['mrp_override'] as num?)?.toDouble(),
      expiryOverride: json['expiry_override'] != null ? DateTime.parse(json['expiry_override']) : null,
    );
  }
}