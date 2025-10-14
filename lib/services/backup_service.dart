import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  Timer? _timer;

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

  Future<void> dispose() async {
    _timer?.cancel();
  }
}


