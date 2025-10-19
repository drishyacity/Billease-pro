import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../dashboard/dashboard_screen.dart';
import '../../services/database_service.dart';

class OnboardingBasicDetailsScreen extends StatefulWidget {
  const OnboardingBasicDetailsScreen({super.key});

  @override
  State<OnboardingBasicDetailsScreen> createState() => _OnboardingBasicDetailsScreenState();
}

class _OnboardingBasicDetailsScreenState extends State<OnboardingBasicDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerName = TextEditingController();
  final _orgName = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _gstin = TextEditingController();
  final _email = TextEditingController();
  String _companyType = 'both';
  bool _isLoading = false;

  @override
  void dispose() {
    _ownerName.dispose();
    _orgName.dispose();
    _phone.dispose();
    _address.dispose();
    _gstin.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final nowIso = DateTime.now().toIso8601String();
    await DatabaseService().upsertCompanyProfile({
      'owner_name': _ownerName.text.trim(),
      'organisation_name': _orgName.text.trim(),
      'contact_phone': _phone.text.trim(),
      'address': _address.text.trim(),
      'gstin': _gstin.text.trim().isEmpty ? null : _gstin.text.trim(),
      'email': _email.text.trim(),
      'company_type': _companyType,
      'created_at': nowIso,
      'updated_at': nowIso,
    });
    setState(() => _isLoading = false);
    Get.offAll(() => const DashboardScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Company details')),
      body: FutureBuilder(
        future: DatabaseService().getCompanyProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data as Map<String, dynamic>?;
          if (data != null) {
            _ownerName.text = data['owner_name'] ?? '';
            _orgName.text = data['organisation_name'] ?? '';
            _phone.text = data['contact_phone'] ?? '';
            _address.text = data['address'] ?? '';
            _gstin.text = data['gstin'] ?? '';
            _email.text = data['email'] ?? '';
            _companyType = data['company_type'] ?? _companyType;
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              SizedBox(
                                width: 380,
                                child: TextFormField(
                                  controller: _ownerName,
                                  decoration: const InputDecoration(labelText: 'Owner name'),
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                ),
                              ),
                              SizedBox(
                                width: 380,
                                child: TextFormField(
                                  controller: _orgName,
                                  decoration: const InputDecoration(labelText: 'Organisation name'),
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                ),
                              ),
                              SizedBox(
                                width: 380,
                                child: TextFormField(
                                  controller: _phone,
                                  decoration: const InputDecoration(labelText: 'Contact phone'),
                                  validator: (v) {
                                    final t = (v ?? '').trim();
                                    if (t.isEmpty) return 'Required';
                                    return RegExp(r'^\d{10}$').hasMatch(t) ? null : 'Enter 10-digit number';
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 380,
                                child: TextFormField(
                                  controller: _email,
                                  decoration: const InputDecoration(labelText: 'Email'),
                                  validator: (v) {
                                    final t = (v ?? '').trim();
                                    if (t.isEmpty) return 'Required';
                                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t) ? null : 'Enter valid email';
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 380,
                                child: TextFormField(
                                  controller: _gstin,
                                  decoration: const InputDecoration(labelText: 'GSTIN (optional)'),
                                ),
                              ),
                              SizedBox(
                                width: 780,
                                child: TextFormField(
                                  controller: _address,
                                  decoration: const InputDecoration(labelText: 'Address'),
                                  maxLines: 2,
                                ),
                              ),
                              DropdownButtonFormField<String>(
                                value: _companyType,
                                decoration: const InputDecoration(labelText: 'Company type'),
                                items: const [
                                  DropdownMenuItem(value: 'wholesale', child: Text('Wholesale')),
                                  DropdownMenuItem(value: 'retail', child: Text('Retail')),
                                  DropdownMenuItem(value: 'both', child: Text('Both')),
                                ],
                                onChanged: (v) => setState(() => _companyType = v ?? 'both'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _isLoading ? null : _save,
                            child: _isLoading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save and continue'),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


