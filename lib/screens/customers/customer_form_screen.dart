import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/customer_controller.dart';
import '../../models/customer_model.dart';

class CustomerFormScreen extends StatefulWidget {
  final Customer? customer;

  const CustomerFormScreen({Key? key, this.customer}) : super(key: key);

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.customer != null) {
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phone;
      _emailController.text = widget.customer!.email ?? '';
      _addressController.text = widget.customer!.address ?? '';
      _gstinController.text = widget.customer!.gstin ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customer == null ? 'Add Customer' : 'Edit Customer'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Name',
                hint: 'Enter customer name',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter customer name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter phone number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  if (value.length < 10) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _emailController,
                label: 'Email (Optional)',
                hint: 'Enter email address',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!GetUtils.isEmail(value)) {
                      return 'Please enter a valid email address';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _addressController,
                label: 'Address (Optional)',
                hint: 'Enter address',
                icon: Icons.location_on,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _gstinController,
                label: 'GSTIN (Optional)',
                hint: 'Enter GSTIN',
                icon: Icons.receipt_long,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    // Basic GSTIN validation
                    if (value.length != 15) {
                      return 'GSTIN should be 15 characters';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveCustomer,
                  child: Text(
                    widget.customer == null ? 'Add Customer' : 'Update Customer',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  void _saveCustomer() {
    if (_formKey.currentState!.validate()) {
      final customerController = Get.find<CustomerController>();
      
      final now = DateTime.now();
      
      if (widget.customer == null) {
        // Create new customer
        final newCustomer = Customer(
          id: 'CUST${now.millisecondsSinceEpoch.toString().substring(0, 8)}',
          name: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          address: _addressController.text.isEmpty ? null : _addressController.text,
          gstin: _gstinController.text.isEmpty ? null : _gstinController.text,
          createdAt: now,
          updatedAt: now,
        );
        
        customerController.addCustomer(newCustomer);
        Get.back();
        Get.snackbar(
          'Success',
          'Customer added successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        // Update existing customer
        final updatedCustomer = Customer(
          id: widget.customer!.id,
          name: _nameController.text,
          phone: _phoneController.text,
          email: _emailController.text.isEmpty ? null : _emailController.text,
          address: _addressController.text.isEmpty ? null : _addressController.text,
          gstin: _gstinController.text.isEmpty ? null : _gstinController.text,
          totalPurchases: widget.customer!.totalPurchases,
          dueAmount: widget.customer!.dueAmount,
          createdAt: widget.customer!.createdAt,
          updatedAt: now,
        );
        
        customerController.updateCustomer(updatedCustomer);
        Get.back();
        Get.snackbar(
          'Success',
          'Customer updated successfully',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }
}