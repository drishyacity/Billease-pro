import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import '../models/bill_model.dart';
import '../services/database_service.dart';
import 'product_controller.dart';

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

  Future<String?> _validateBill(Bill bill) async {
    if (bill.items.isEmpty) return 'Please add at least one item';
    final dbi = await DatabaseService().database;
    for (final it in bill.items) {
      if (it.productId.isEmpty) return 'One or more items have no product selected.';
      final prod = await dbi.query('products', where: 'id = ?', whereArgs: [it.productId], limit: 1);
      if (prod.isEmpty) return 'Product ${it.productName} is not available locally. Please sync products.';
      if (it.batchId != null) {
        final batch = await dbi.query('batches', where: 'id = ?', whereArgs: [it.batchId], limit: 1);
        if (batch.isEmpty) return 'Selected batch for ${it.productName} no longer exists. Please reselect.';
        if (batch.first['product_id'] != it.productId) return 'Selected batch does not belong to ${it.productName}.';
      }
      if (it.quantity <= 0) return 'Quantity for ${it.productName} must be greater than 0';
      if (it.unitPrice < 0) return 'Unit price for ${it.productName} cannot be negative';
    }
    return null;
  }

  void filterBills({String? searchQuery, DateTime? from, DateTime? to}) {
    Iterable<Bill> source = _bills;
    if (from != null || to != null) {
      final start = from != null ? DateTime(from.year, from.month, from.day) : null;
      final end = to != null ? DateTime(to.year, to.month, to.day, 23, 59, 59, 999) : null;
      source = source.where((b) {
        final d = b.date;
        final after = start == null || !d.isBefore(start);
        final before = end == null || !d.isAfter(end);
        return after && before;
      });
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      source = source.where((bill) =>
          bill.id.toLowerCase().contains(q) ||
          (bill.customerName != null && bill.customerName!.toLowerCase().contains(q)));
    }
    _filteredBills.value = source.toList();
  }

  Future<void> loadBills() async {
    _isLoading.value = true;
    try {
      final db = DatabaseService();
      final billRows = await db.getAllBills();
      final List<Bill> loaded = [];
      for (final row in billRows) {
        final rawItems = await db.getBillItems(row['id'] as String);
        // Map DB snake_case to model's expected keys
        final items = rawItems.map((it) => {
          'id': it['id'],
          'productId': it['product_id'],
          'productName': it['product_name'],
          'quantity': it['quantity'],
          'unitPrice': it['unit_price'],
          'totalPrice': it['total_price'],
          'batch_id': it['batch_id'],
          'unit': it['unit'],
          'cgst': it['cgst'],
          'sgst': it['sgst'],
          'discount_percent': it['discount_percent'],
          'mrp_override': it['mrp_override'],
          'expiry_override': it['expiry_override'],
        }).toList();
        final bill = Bill.fromJson({
          'id': row['id'],
          'date': row['date'],
          'type': row['type'],
          'customerId': row['customer_id'],
          'customerName': row['customer_name'],
          'items': items,
          'totalAmount': row['total_amount'],
          'paidAmount': row['paid_amount'],
          'status': row['status'],
          'notes': row['notes'],
          'finalDiscountValue': row['final_discount_value'],
          'finalDiscountIsPercent': (row['final_discount_is_percent'] ?? 1) == 1,
          'extraAmount': row['extra_amount'],
          'extraAmountName': row['extra_amount_name'],
          'gstEnabled': (row['gst_enabled'] ?? 0) == 1,
          'inlineGst': (row['inline_gst'] ?? 1) == 1,
        });
        loaded.add(bill);
      }
      _bills.value = loaded;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load bills: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      _filteredBills.value = _bills;
      // Refresh product list
      try { await Get.find<ProductController>().loadProducts(); } catch (_) {}
      _isLoading.value = false;
    }
  }

  Future<void> addBill(Bill bill) async {
    _isLoading.value = true;
    try {
      final validation = await _validateBill(bill);
      if (validation != null) {
        Get.snackbar('Cannot save bill', validation, snackPosition: SnackPosition.TOP);
        return;
      }
      final db = DatabaseService();
      await db.insertBill(bill.toJson(), bill.items.map((e) => e.toJson()..['bill_id'] = bill.id).toList());
      // Adjust stock for completed bills
      if (bill.status == BillStatus.completed) {
        for (final it in bill.items) {
          if (it.batchId != null) {
            final double delta = -it.quantity; // keep decimals
            await db.adjustBatchStock(batchId: it.batchId!, delta: delta);
          }
        }
      }
      _bills.add(bill);
      _filteredBills.value = _bills;
      // Refresh product list
      try { await Get.find<ProductController>().loadProducts(); } catch (_) {}
      Get.snackbar(
        'Success',
        'Bill created successfully',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      // Debug log for developers while keeping user-friendly snackbar
      // ignore: avoid_print
      print('addBill error: $e');
      final msg = _friendlyBillError(e);
      Get.snackbar('Error', msg, snackPosition: SnackPosition.TOP);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> updateBill(Bill bill) async {
    _isLoading.value = true;
    try {
      final validation = await _validateBill(bill);
      if (validation != null) {
        Get.snackbar('Cannot save bill', validation, snackPosition: SnackPosition.TOP);
        return;
      }
      final db = DatabaseService();
      // Compute stock adjustments relative to existing bill if any
      final existingIndex = _bills.indexWhere((b) => b.id == bill.id);
      Bill? old = existingIndex != -1 ? _bills[existingIndex] : null;
      // Upsert bill in DB
      await db.insertBill(
        bill.toJson(),
        bill.items.map((e) => e.toJson()..['bill_id'] = bill.id).toList(),
      );
      // Apply stock diffs
      if (old != null) {
        final oldCompleted = old.status == BillStatus.completed;
        final newCompleted = bill.status == BillStatus.completed;
        Map<String, double> qtyOld = {};
        for (final it in old.items) {
          if (it.batchId != null) {
            qtyOld[it.batchId!] = (qtyOld[it.batchId!] ?? 0) + it.quantity;
          }
        }
        Map<String, double> qtyNew = {};
        for (final it in bill.items) {
          if (it.batchId != null) {
            qtyNew[it.batchId!] = (qtyNew[it.batchId!] ?? 0) + it.quantity;
          }
        }
        if (oldCompleted && newCompleted) {
          // apply difference: new - old (deduct positive delta, add back negative)
          final keys = {...qtyOld.keys, ...qtyNew.keys};
          for (final k in keys) {
            final double oldQ = qtyOld[k] ?? 0;
            final double newQ = qtyNew[k] ?? 0;
            final double diff = newQ - oldQ;
            if (diff != 0) {
              await db.adjustBatchStock(batchId: k, delta: -diff);
            }
          }
        } else if (!oldCompleted && newCompleted) {
          // newly completed: deduct all new quantities
          for (final entry in qtyNew.entries) {
            await db.adjustBatchStock(batchId: entry.key, delta: -entry.value);
          }
        } else if (oldCompleted && !newCompleted) {
          // moved away from completed: add back all old quantities
          for (final entry in qtyOld.entries) {
            await db.adjustBatchStock(batchId: entry.key, delta: entry.value);
          }
        }
      } else {
        // No old bill known locally; if completed, deduct all
        if (bill.status == BillStatus.completed) {
          for (final it in bill.items) {
            if (it.batchId != null) {
              await db.adjustBatchStock(batchId: it.batchId!, delta: -it.quantity);
            }
          }
        }
      }
      // Update in-memory list
      if (existingIndex != -1) {
        _bills[existingIndex] = bill;
      } else {
        _bills.add(bill);
      }
      _filteredBills.value = _bills;
      Get.snackbar(
        'Success',
        'Bill updated successfully',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      // ignore: avoid_print
      print('updateBill error: $e');
      final msg = _friendlyBillError(e);
      Get.snackbar('Error', msg, snackPosition: SnackPosition.TOP);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteBill(String id) async {
    _isLoading.value = true;
    try {
      final db = DatabaseService();
      // Find bill to revert stock if completed
      final idx = _bills.indexWhere((b) => b.id == id);
      if (idx != -1) {
        final bill = _bills[idx];
        if (bill.status == BillStatus.completed) {
          for (final it in bill.items) {
            if (it.batchId != null) {
              await db.adjustBatchStock(batchId: it.batchId!, delta: it.quantity);
            }
          }
        }
      }
      await db.deleteBillById(id);
      _bills.removeWhere((bill) => bill.id == id);
      _filteredBills.value = _bills;
      // Refresh product list
      try { await Get.find<ProductController>().loadProducts(); } catch (_) {}
      Get.snackbar(
        'Success',
        'Bill deleted successfully',
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete bill: ${e.toString()}',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      _isLoading.value = false;
    }
  }
}

extension BillControllerFriendlyErrors on BillController {
  String _friendlyBillError(Object e) {
    if (e is DatabaseException) {
      final msg = e.toString();
      if (msg.contains('UNIQUE constraint failed: bills.id')) {
        return 'A bill with this ID already exists.';
      }
      if (msg.contains('NOT NULL')) {
        return 'Please fill all required fields before saving the bill.';
      }
      if (msg.contains('FOREIGN KEY')) {
        return 'Some items reference missing products or batches. Please review bill items.';
      }
      return 'Could not save the bill. Please review the fields and try again.';
    }
    return 'Could not save the bill. Please try again.';
  }
}