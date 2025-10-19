import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'supabase_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;
  String _currentUserKey = 'anonymous';

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  // Purchases
  Future<List<Map<String, dynamic>>> getAllPurchases() async {
    final db = await database;
    return db.query('purchases', orderBy: 'date DESC');
  }

  Future<void> insertPurchase(Map<String, dynamic> purchase, List<Map<String, dynamic>> items) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert('purchases', purchase, conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete('purchase_items', where: 'purchase_id = ?', whereArgs: [purchase['id']]);
      for (final it in items) {
        final data = Map<String, Object?>.from(it);
        data['purchase_id'] = purchase['id'];
        await txn.insert('purchase_items', data, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getPurchaseItems(String purchaseId) async {
    final db = await database;
    return db.query('purchase_items', where: 'purchase_id = ?', whereArgs: [purchaseId]);
  }

  Future<void> setCurrentUser(String? userId) async {
    final newKey = (userId == null || userId.isEmpty) ? 'anonymous' : userId;
    if (newKey == _currentUserKey && _db != null) return;
    _currentUserKey = newKey;
    await close();
    _db = await _initDb();
  }

  Future<List<Map<String, dynamic>>> getBatchesByProductId(String productId) async {
    final db = await database;
    return db.query('batches', where: 'product_id = ?', whereArgs: [productId]);
  }

  Future<Map<String, dynamic>?> getBatchById(String batchId) async {
    final db = await database;
    final rows = await db.query('batches', where: 'id = ?', whereArgs: [batchId], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> adjustBatchStock({required String batchId, required double delta}) async {
    final db = await database;
    await db.transaction((txn) async {
      final rows = await txn.query('batches', where: 'id = ?', whereArgs: [batchId], limit: 1);
      if (rows.isEmpty) return;
      final currentNum = rows.first['stock'] as num?; // INTEGER affinity may still store REAL
      final current = (currentNum ?? 0).toDouble();
      final newStock = current + delta; // delta negative to deduct
      await txn.update('batches', {'stock': newStock}, where: 'id = ?', whereArgs: [batchId]);
    });
  }

  Future<Database> _initDb() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final safeKey = _currentUserKey.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final dbPath = p.join(docsDir.path, 'billease_pro_${safeKey}.db');
    return await openDatabase(
      dbPath,
      version: 8,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add per-bill override fields to bill_items
          await db.execute('ALTER TABLE bill_items ADD COLUMN mrp_override REAL');
          await db.execute('ALTER TABLE bill_items ADD COLUMN expiry_override TEXT');
        }
        if (oldVersion < 3) {
          await db.execute('CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_products_category ON products(category)');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_batches_product_id ON batches(product_id)');
        }
        if (oldVersion < 4) {
          try { await db.execute('ALTER TABLE products ADD COLUMN cgst_percentage REAL DEFAULT 0'); } catch (_) {}
          try { await db.execute('ALTER TABLE products ADD COLUMN sgst_percentage REAL DEFAULT 0'); } catch (_) {}
          try { await db.execute('ALTER TABLE products ADD COLUMN discount_percentage REAL DEFAULT 0'); } catch (_) {}
        }
        if (oldVersion < 5) {
          try { await db.execute('ALTER TABLE bills ADD COLUMN final_discount_value REAL DEFAULT 0'); } catch (_) {}
          try { await db.execute('ALTER TABLE bills ADD COLUMN final_discount_is_percent INTEGER DEFAULT 1'); } catch (_) {}
          try { await db.execute('ALTER TABLE bills ADD COLUMN extra_amount REAL DEFAULT 0'); } catch (_) {}
          try { await db.execute('ALTER TABLE bills ADD COLUMN extra_amount_name TEXT'); } catch (_) {}
        }
        if (oldVersion < 6) {
          try { await db.execute('ALTER TABLE bills ADD COLUMN gst_enabled INTEGER DEFAULT 0'); } catch (_) {}
          try { await db.execute('ALTER TABLE bills ADD COLUMN inline_gst INTEGER DEFAULT 1'); } catch (_) {}
        }
        if (oldVersion < 7) {
          // Harden migration: ensure all expected bill columns exist
          try { await db.execute('ALTER TABLE bills ADD COLUMN final_discount_value REAL DEFAULT 0'); } catch (_) {}
          try { await db.execute('ALTER TABLE bills ADD COLUMN final_discount_is_percent INTEGER DEFAULT 1'); } catch (_) {}
          try { await db.execute('ALTER TABLE bills ADD COLUMN extra_amount REAL DEFAULT 0'); } catch (_) {}
          try { await db.execute('ALTER TABLE bills ADD COLUMN extra_amount_name TEXT'); } catch (_) {}
          try { await db.execute('ALTER TABLE bills ADD COLUMN gst_enabled INTEGER DEFAULT 0'); } catch (_) {}
          try { await db.execute('ALTER TABLE bills ADD COLUMN inline_gst INTEGER DEFAULT 1'); } catch (_) {}
        }
        if (oldVersion < 8) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS purchases (
              id TEXT PRIMARY KEY,
              date TEXT NOT NULL,
              vendor_name TEXT,
              total_amount REAL NOT NULL,
              paid_amount REAL DEFAULT 0,
              notes TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS purchase_items (
              id TEXT PRIMARY KEY,
              purchase_id TEXT NOT NULL,
              product_id TEXT,
              description TEXT,
              quantity REAL NOT NULL,
              unit_price REAL NOT NULL,
              total_price REAL NOT NULL,
              FOREIGN KEY(purchase_id) REFERENCES purchases(id) ON DELETE CASCADE,
              FOREIGN KEY(product_id) REFERENCES products(id)
            )
          ''');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase_id ON purchase_items(purchase_id)');
        }
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        // Ensure critical columns exist even if DB version is already at latest
        try { await db.execute('ALTER TABLE bills ADD COLUMN final_discount_value REAL DEFAULT 0'); } catch (_) {}
        try { await db.execute('ALTER TABLE bills ADD COLUMN final_discount_is_percent INTEGER DEFAULT 1'); } catch (_) {}
        try { await db.execute('ALTER TABLE bills ADD COLUMN extra_amount REAL DEFAULT 0'); } catch (_) {}
        try { await db.execute('ALTER TABLE bills ADD COLUMN extra_amount_name TEXT'); } catch (_) {}
        try { await db.execute('ALTER TABLE bills ADD COLUMN gst_enabled INTEGER DEFAULT 0'); } catch (_) {}
        try { await db.execute('ALTER TABLE bills ADD COLUMN inline_gst INTEGER DEFAULT 1'); } catch (_) {}
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE,
        password_hash TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Purchases (to support dashboard sales vs purchases and bookkeeping)
    await db.execute('''
      CREATE TABLE purchases (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        vendor_name TEXT,
        total_amount REAL NOT NULL,
        paid_amount REAL DEFAULT 0,
        notes TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE purchase_items (
        id TEXT PRIMARY KEY,
        purchase_id TEXT NOT NULL,
        product_id TEXT,
        description TEXT,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        FOREIGN KEY(purchase_id) REFERENCES purchases(id) ON DELETE CASCADE,
        FOREIGN KEY(product_id) REFERENCES products(id)
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_purchase_items_purchase_id ON purchase_items(purchase_id)');

    // Company profile
    await db.execute('''
      CREATE TABLE company_profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        owner_name TEXT,
        organisation_name TEXT,
        contact_phone TEXT,
        address TEXT,
        gstin TEXT,
        email TEXT,
        company_type TEXT, -- wholesale | retail | both
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Products
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        barcode TEXT,
        category TEXT,
        primary_unit TEXT NOT NULL,
        gst_percentage REAL DEFAULT 0,
        low_stock_alert INTEGER DEFAULT 10,
        expiry_alert_days INTEGER DEFAULT 30,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Units conversion
    await db.execute('''
      CREATE TABLE unit_conversions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id TEXT NOT NULL,
        base_unit TEXT NOT NULL,
        converted_unit TEXT NOT NULL,
        conversion_factor REAL NOT NULL,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    // Batches
    await db.execute('''
      CREATE TABLE batches (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        name TEXT NOT NULL,
        cost_price REAL NOT NULL,
        selling_price REAL NOT NULL,
        mrp REAL NOT NULL,
        expiry_date TEXT,
        stock INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    // Customers
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT,
        address TEXT,
        gstin TEXT,
        total_purchases REAL DEFAULT 0,
        due_amount REAL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Bills
    await db.execute('''
      CREATE TABLE bills (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        type TEXT NOT NULL, -- quickSale | retail | wholesale
        customer_id TEXT,
        customer_name TEXT,
        total_amount REAL NOT NULL,
        paid_amount REAL DEFAULT 0,
        status TEXT NOT NULL, -- draft | completed | partiallyPaid | fullyPaid
        notes TEXT,
        final_discount_value REAL DEFAULT 0,
        final_discount_is_percent INTEGER DEFAULT 1,
        extra_amount REAL DEFAULT 0,
        extra_amount_name TEXT,
        gst_enabled INTEGER DEFAULT 0,
        inline_gst INTEGER DEFAULT 1,
        FOREIGN KEY(customer_id) REFERENCES customers(id)
      )
    ''');

    // Bill items
    await db.execute('''
      CREATE TABLE bill_items (
        id TEXT PRIMARY KEY,
        bill_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        product_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        batch_id TEXT,
        unit TEXT,
        cgst REAL,
        sgst REAL,
        discount_percent REAL,
        mrp_override REAL,
        expiry_override TEXT,
        FOREIGN KEY(bill_id) REFERENCES bills(id) ON DELETE CASCADE,
        FOREIGN KEY(product_id) REFERENCES products(id),
        FOREIGN KEY(batch_id) REFERENCES batches(id)
      )
    ''');

    // Settings
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_name ON products(name)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_products_category ON products(category)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_batches_product_id ON batches(product_id)');
    // Ensure new columns exist on fresh DBs
    await db.execute('ALTER TABLE products ADD COLUMN cgst_percentage REAL DEFAULT 0');
    await db.execute('ALTER TABLE products ADD COLUMN sgst_percentage REAL DEFAULT 0');
    await db.execute('ALTER TABLE products ADD COLUMN discount_percentage REAL DEFAULT 0');
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  // Company profile
  Future<Map<String, dynamic>?> getCompanyProfile() async {
    final db = await database;
    final rows = await db.query('company_profile', limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  Future<void> upsertCompanyProfile(Map<String, dynamic> data) async {
    final db = await database;
    data['id'] = 1;
    await db.insert(
      'company_profile',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Products minimal APIs (without full relations handling for brevity)
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    return db.query('products');
  }

  Future<List<Map<String, dynamic>>> getAllProductsWithRelations() async {
    final db = await database;
    final products = await db.query('products');
    final List<Map<String, dynamic>> result = [];
    for (final p in products) {
      final batches = await db.query('batches', where: 'product_id = ?', whereArgs: [p['id']]);
      final unitRows = await db.query('unit_conversions', where: 'product_id = ?', whereArgs: [p['id']]);
      result.add({
        'id': p['id'],
        'name': p['name'],
        'barcode': p['barcode'],
        'category': p['category'],
        'primaryUnit': p['primary_unit'],
        'unitConversions': unitRows.map((e) => {
          'baseUnit': e['base_unit'],
          'convertedUnit': e['converted_unit'],
          'conversionFactor': e['conversion_factor'],
        }).toList(),
        'batches': batches.map((b) => {
          'id': b['id'],
          'name': b['name'],
          'costPrice': b['cost_price'],
          'sellingPrice': b['selling_price'],
          'mrp': b['mrp'],
          'expiryDate': b['expiry_date'],
          'stock': b['stock'],
        }).toList(),
        'gstPercentage': p['gst_percentage'],
        'cgstPercentage': p['cgst_percentage'] ?? 0.0,
        'sgstPercentage': p['sgst_percentage'] ?? 0.0,
        'discountPercentage': p['discount_percentage'] ?? 0.0,
        'lowStockAlert': p['low_stock_alert'],
        'expiryAlertDays': p['expiry_alert_days'],
        'createdAt': p['created_at'],
        'updatedAt': p['updated_at'],
      });
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> getProductsWithRelationsPage({required int limit, required int offset}) async {
    final db = await database;
    final products = await db.query('products', limit: limit, offset: offset);
    final List<Map<String, dynamic>> result = [];
    for (final p in products) {
      final batches = await db.query('batches', where: 'product_id = ?', whereArgs: [p['id']]);
      final unitRows = await db.query('unit_conversions', where: 'product_id = ?', whereArgs: [p['id']]);
      result.add({
        'id': p['id'],
        'name': p['name'],
        'barcode': p['barcode'],
        'category': p['category'],
        'primaryUnit': p['primary_unit'],
        'unitConversions': unitRows.map((e) => {
          'baseUnit': e['base_unit'],
          'convertedUnit': e['converted_unit'],
          'conversionFactor': e['conversion_factor'],
        }).toList(),
        'batches': batches.map((b) => {
          'id': b['id'],
          'name': b['name'],
          'costPrice': b['cost_price'],
          'sellingPrice': b['selling_price'],
          'mrp': b['mrp'],
          'expiryDate': b['expiry_date'],
          'stock': b['stock'],
        }).toList(),
        'gstPercentage': p['gst_percentage'],
        'cgstPercentage': p['cgst_percentage'] ?? 0.0,
        'sgstPercentage': p['sgst_percentage'] ?? 0.0,
        'discountPercentage': p['discount_percentage'] ?? 0.0,
        'lowStockAlert': p['low_stock_alert'],
        'expiryAlertDays': p['expiry_alert_days'],
        'createdAt': p['created_at'],
        'updatedAt': p['updated_at'],
      });
    }
    return result;
  }

  Future<void> deleteCurrentDbFile() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final safeKey = _currentUserKey.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final dbPath = p.join(docsDir.path, 'billease_pro_${safeKey}.db');
    await close();
    final f = File(dbPath);
    if (await f.exists()) {
      await f.delete();
    }
  }

  Future<void> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    await db.insert('products', product, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertProduct(Map<String, dynamic> product) async {
    final db = await database;
    await db.insert('products', product, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateProductFields(Map<String, dynamic> product) async {
    final db = await database;
    final data = Map<String, Object?>.from(product);
    await db.update(
      'products',
      data,
      where: 'id = ?',
      whereArgs: [product['id']],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<Map<String, dynamic>?> findProductByBarcodeOrName({String? barcode, String? name}) async {
    final db = await database;
    if (barcode != null && barcode.isNotEmpty) {
      final rows = await db.query('products', where: 'barcode = ?', whereArgs: [barcode], limit: 1);
      if (rows.isNotEmpty) return rows.first;
    }
    if (name != null && name.isNotEmpty) {
      final rows = await db.query('products', where: 'LOWER(name) = LOWER(?)', whereArgs: [name], limit: 1);
      if (rows.isNotEmpty) return rows.first;
    }
    return null;
  }

  Future<void> insertBatch(Map<String, dynamic> batch) async {
    final db = await database;
    await db.insert('batches', batch, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateBatch(Map<String, dynamic> batch) async {
    final db = await database;
    await db.update(
      'batches',
      batch,
      where: 'id = ?',
      whereArgs: [batch['id']],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteBatchById(String batchId) async {
    final db = await database;
    await db.delete('batches', where: 'id = ?', whereArgs: [batchId]);
  }

  // Customers
  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final db = await database;
    return db.query('customers');
  }

  Future<void> upsertCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    // map to snake_case columns
    final data = <String, Object?>{
      'id': customer['id'],
      'name': customer['name'],
      'phone': customer['phone'],
      'email': customer['email'],
      'address': customer['address'],
      'gstin': customer['gstin'],
      'total_purchases': customer['totalPurchases'] ?? 0,
      'due_amount': customer['dueAmount'] ?? 0,
      'created_at': customer['createdAt'],
      'updated_at': customer['updatedAt'],
    };
    await db.insert('customers', data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCustomerById(String id) async {
    final db = await database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> findCustomerByPhoneOrName({String? phone, String? name}) async {
    final db = await database;
    if (phone != null && phone.isNotEmpty) {
      final rows = await db.query('customers', where: 'phone = ?', whereArgs: [phone], limit: 1);
      if (rows.isNotEmpty) return rows.first;
    }
    if (name != null && name.isNotEmpty) {
      final rows = await db.query('customers', where: 'LOWER(name) = LOWER(?)', whereArgs: [name], limit: 1);
      if (rows.isNotEmpty) return rows.first;
    }
    return null;
  }

  Future<void> deleteProductById(String productId) async {
    final db = await database;
    await db.delete('batches', where: 'product_id = ?', whereArgs: [productId]);
    await db.delete('unit_conversions', where: 'product_id = ?', whereArgs: [productId]);
    await db.delete('products', where: 'id = ?', whereArgs: [productId]);
  }

  // Bills
  Future<List<Map<String, dynamic>>> getAllBills() async {
    final db = await database;
    return db.query('bills', orderBy: 'date DESC');
  }

  Future<void> insertBill(Map<String, dynamic> bill, List<Map<String, dynamic>> items) async {
    final db = await database;
    await db.transaction((txn) async {
      // Replace bill row
      final billData = <String, Object?>{
        'id': bill['id'],
        'date': bill['date'],
        'type': bill['type'],
        'customer_id': bill['customerId'],
        'customer_name': bill['customerName'],
        'total_amount': bill['totalAmount'],
        'paid_amount': bill['paidAmount'],
        'status': bill['status'],
        'notes': bill['notes'],
        'final_discount_value': bill['finalDiscountValue'] ?? 0,
        'final_discount_is_percent': (bill['finalDiscountIsPercent'] == true) ? 1 : 0,
        'extra_amount': bill['extraAmount'] ?? 0,
        'extra_amount_name': bill['extraAmountName'],
        'gst_enabled': (bill['gstEnabled'] == true) ? 1 : 0,
        'inline_gst': (bill['inlineGst'] == false) ? 0 : 1,
      };
      final billCols = await txn.rawQuery('PRAGMA table_info(bills)');
      final existingBillCols = billCols.map((e) => e['name'] as String).toSet();
      final billFiltered = Map<String, Object?>.fromEntries(
        billData.entries.where((e) => existingBillCols.contains(e.key)),
      );
      await txn.insert('bills', billFiltered, conflictAlgorithm: ConflictAlgorithm.replace);
      // Remove existing items for this bill to avoid duplicates on edit
      await txn.delete('bill_items', where: 'bill_id = ?', whereArgs: [bill['id']]);
      for (final item in items) {
        final itemData = <String, Object?>{
          'id': item['id'],
          'bill_id': item['bill_id'],
          'product_id': item['productId'],
          'product_name': item['productName'],
          'quantity': item['quantity'],
          'unit_price': item['unitPrice'],
          'total_price': item['totalPrice'],
          'batch_id': item['batch_id'],
          'unit': item['unit'],
          'cgst': item['cgst'],
          'sgst': item['sgst'],
          'discount_percent': item['discount_percent'],
          'mrp_override': item['mrp_override'],
          'expiry_override': item['expiry_override'],
        };
        final itemCols = await txn.rawQuery('PRAGMA table_info(bill_items)');
        final existingItemCols = itemCols.map((e) => e['name'] as String).toSet();
        final itemFiltered = Map<String, Object?>.fromEntries(
          itemData.entries.where((e) => existingItemCols.contains(e.key)),
        );
        await txn.insert('bill_items', itemFiltered, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getBillItems(String billId) async {
    final db = await database;
    return db.query('bill_items', where: 'bill_id = ?', whereArgs: [billId]);
  }

  Future<void> deleteBillById(String billId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('bill_items', where: 'bill_id = ?', whereArgs: [billId]);
      await txn.delete('bills', where: 'id = ?', whereArgs: [billId]);
    });
  }
}

extension Maintenance on DatabaseService {
  Future<void> clearDemoData() async {
    final db = await database;
    await db.delete('bill_items');
    await db.delete('bills');
    await db.delete('batches');
    await db.delete('unit_conversions');
    await db.delete('products');
    await db.delete('customers');
  }
}

extension BackupHelpers on DatabaseService {
  Future<List<Map<String, dynamic>>> getAllBatches() async {
    final db = await database;
    return db.query('batches');
  }

  Future<List<Map<String, dynamic>>> getAllUnitConversions() async {
    final db = await database;
    return db.query('unit_conversions');
  }

  Future<List<Map<String, dynamic>>> getAllSettings() async {
    final db = await database;
    return db.query('settings');
  }
}
