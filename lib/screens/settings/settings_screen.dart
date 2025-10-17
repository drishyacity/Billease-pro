import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/database_service.dart';
import '../onboarding/onboarding_basic_details_screen.dart';
import '../../services/backup_service.dart';
import '../../services/supabase_service.dart';
import '../auth/login_screen.dart';
import '../../controllers/product_controller.dart';
import '../../controllers/bill_controller.dart';
import '../../controllers/customer_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.business),
            title: const Text('Company Details'),
            subtitle: const Text('Update organisation profile, GST, contact'),
            onTap: () => Get.to(() => const OnboardingBasicDetailsScreen()),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Staff Management'),
            subtitle: const Text('Add or manage staff (coming soon)'),
            onTap: () {
              Get.snackbar('Info', 'Staff management will be implemented soon', snackPosition: SnackPosition.TOP);
            },
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.save_alt),
            title: const Text('Create Local Backup'),
            subtitle: const Text('Saves a copy of the database to backups folder'),
            onTap: () async {
              try {
                final file = await BackupService().createBackup();
                Get.snackbar('Backup Created', 'Saved to: ${file.path}', snackPosition: SnackPosition.TOP, duration: const Duration(seconds: 4));
              } catch (e) {
                Get.snackbar('Backup Failed', e.toString(), snackPosition: SnackPosition.TOP);
              }
            },
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('Manual Cloud Backup Now'),
            subtitle: const Text('Uploads latest data snapshot to cloud storage'),
            onTap: () async {
              try {
                await BackupService().manualCloudBackup();
                Get.snackbar('Backup Uploaded', 'Cloud backup completed', snackPosition: SnackPosition.TOP);
              } catch (e) {
                Get.snackbar('Upload Failed', e.toString(), snackPosition: SnackPosition.TOP);
              }
            },
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            subtitle: const Text('Sign out from this device'),
            onTap: () async {
              try {
                await SupabaseService().signOut();
                // Clear in-memory data
                try { Get.find<ProductController>().products.clear(); } catch (_) {}
                try { Get.find<BillController>().bills.clear(); } catch (_) {}
                try { Get.find<CustomerController>(); } catch (_) {}
                // Delete per-user DB file and switch to anonymous
                await DatabaseService().deleteCurrentDbFile();
                await DatabaseService().setCurrentUser(null);
                // Navigate to login
                Get.offAll(() => const LoginScreen());
              } catch (e) {
                Get.snackbar('Logout Failed', e.toString(), snackPosition: SnackPosition.TOP);
              }
            },
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Clear Demo Data'),
            subtitle: const Text('Remove all sample entries'),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm'),
                  content: const Text('This will clear demo data. Continue?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
                  ],
                ),
              );
              if (ok == true) {
                try {
                  await DatabaseService().clearDemoData();
                  Get.snackbar('Success', 'Demo data cleared', snackPosition: SnackPosition.TOP);
                } catch (e) {
                  Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.TOP);
                }
              }
            },
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('About', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('BillEase Pro'),
            subtitle: Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }
}


