import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<List<Map<String, dynamic>>> getBatchesByProductId(String productId) async {
    final db = await database;
    return db.query('batches', where: 'product_id = ?', whereArgs: [productId]);
  }

  Future<Database> _initDb() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, 'billease_pro.db');
    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
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
        'lowStockAlert': p['low_stock_alert'],
        'expiryAlertDays': p['expiry_alert_days'],
        'createdAt': p['created_at'],
        'updatedAt': p['updated_at'],
      });
    }
    return result;
  }

  Future<void> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    await db.insert('products', product, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> upsertProduct(Map<String, dynamic> product) async {
    final db = await database;
    await db.insert('products', product, conflictAlgorithm: ConflictAlgorithm.replace);
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
      };
      await txn.insert('bills', billData, conflictAlgorithm: ConflictAlgorithm.replace);
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
        };
        await txn.insert('bill_items', itemData, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getBillItems(String billId) async {
    final db = await database;
    return db.query('bill_items', where: 'bill_id = ?', whereArgs: [billId]);
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
