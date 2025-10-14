import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/database_service.dart';
import '../onboarding/onboarding_basic_details_screen.dart';

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
              Get.snackbar('Info', 'Staff management will be implemented soon', snackPosition: SnackPosition.BOTTOM);
            },
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup & Restore'),
            subtitle: const Text('Manage local backups (coming soon)'),
            onTap: () {
              Get.snackbar('Info', 'Backup options will be implemented soon', snackPosition: SnackPosition.BOTTOM);
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
                  Get.snackbar('Success', 'Demo data cleared', snackPosition: SnackPosition.BOTTOM);
                } catch (e) {
                  Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
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


