import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'database_service.dart';
import 'supabase_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  Timer? _timer;
  StreamSubscription<ConnectivityResult>? _connSub;
  Timer? _cloudTimer;

  Future<void> startAutoBackup() async {
    _timer?.cancel();
    // Every 12 hours
    _timer = Timer.periodic(const Duration(hours: 12), (_) => createBackup());
  }

  Future<File> createBackup() async {
    final docs = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docs.path, 'billease_pro.db');
    final backupsDir = Directory(p.join(docs.path, 'backups'));
    if (!await backupsDir.exists()) {
      await backupsDir.create(recursive: true);
    }
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = p.join(backupsDir.path, 'backup_$timestamp.db');
    final src = File(dbPath);
    return src.copy(backupPath);
  }

  Future<void> startNetworkSync() async {
    _connSub?.cancel();
    _cloudTimer?.cancel();
    // Immediate attempt if currently online
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      unawaited(_uploadSnapshotSafe());
    }
    // Listen for connectivity changes
    _connSub = Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        unawaited(_uploadSnapshotSafe());
      }
    });
    // Periodic background cloud backup every 6 hours
    _cloudTimer = Timer.periodic(const Duration(hours: 6), (_) => _uploadSnapshotSafe());
  }

  Future<void> manualCloudBackup() async {
    await _uploadSnapshot();
  }

  Future<void> _uploadSnapshotSafe() async {
    try {
      await _uploadSnapshot();
    } catch (_) {
      // ignore, will retry on next interval/connectivity
    }
  }

  Future<void> _uploadSnapshot() async {
    // Build JSON export of key tables
    final export = await _buildJsonExport();
    final userId = SupabaseService().currentUserId ?? 'anonymous';
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = 'export_$timestamp.json';

    // Write to temp file
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, fileName));
    await file.writeAsString(jsonEncode(export));

    // Upload to Supabase Storage bucket "backups"
    final client = SupabaseService().client;
    await client.storage.from('backups').upload(
      'users/$userId/$fileName',
      file,
    );
  }

  Future<Map<String, dynamic>> _buildJsonExport() async {
    final db = DatabaseService();
    final products = await db.getAllProducts();
    final customers = await db.getAllCustomers();
    final bills = await db.getAllBills();
    final company = await db.getCompanyProfile();
    final batches = await db.getAllBatches();
    final unitConversions = await db.getAllUnitConversions();
    final settings = await db.getAllSettings();

    // gather bill items per bill
    final Map<String, List<Map<String, dynamic>>> billItems = {};
    for (final b in bills) {
      final id = b['id'] as String;
      billItems[id] = await db.getBillItems(id);
    }

    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'companyProfile': company,
      'products': products,
      'batches': batches,
      'unitConversions': unitConversions,
      'customers': customers,
      'bills': bills,
      'billItems': billItems,
      'settings': settings,
      'appVersion': '1.0.0',
    };
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _cloudTimer?.cancel();
    await _connSub?.cancel();
  }
}


