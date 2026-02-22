import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/asset.dart';

class AddAssetPage extends StatefulWidget {
  const AddAssetPage({super.key});

  @override
  State<AddAssetPage> createState() => _AddAssetPageState();
}

class _AddAssetPageState extends State<AddAssetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _serialNumberController = TextEditingController();
  final _locationController = TextEditingController();
  final _valueController = TextEditingController();
  final _assignedToController = TextEditingController();

  AssetCategory _selectedCategory = AssetCategory.electronics;
  AssetStatus _selectedStatus = AssetStatus.active;
  DateTime _purchaseDate = DateTime.now();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _serialNumberController.dispose();
    _locationController.dispose();
    _valueController.dispose();
    _assignedToController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd.MM.yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text(AppStrings.addAsset),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _saveAsset,
              child: const Text(
                AppStrings.save,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo placeholder
              Center(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_rounded,
                          color: AppColors.primary.withValues(alpha: 0.5),
                          size: 36,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Adaugă foto',
                          style: TextStyle(
                            color: AppColors.primary.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Section: Info de bază
              _SectionTitle(title: 'Informații de bază'),
              const SizedBox(height: 14),

              _buildTextField(
                controller: _nameController,
                label: AppStrings.assetName,
                icon: Icons.inventory_2_outlined,
                required: true,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _descriptionController,
                label: AppStrings.assetDescription,
                icon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _serialNumberController,
                label: AppStrings.assetSerialNumber,
                icon: Icons.qr_code_rounded,
              ),
              const SizedBox(height: 24),

              // Section: Clasificare
              _SectionTitle(title: 'Clasificare'),
              const SizedBox(height: 14),

              // Category Dropdown
              _buildDropdown<AssetCategory>(
                label: AppStrings.assetCategory,
                icon: Icons.category_outlined,
                value: _selectedCategory,
                items: AssetCategory.values.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text(_categoryLabel(c)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 16),

              // Status Dropdown
              _buildDropdown<AssetStatus>(
                label: AppStrings.assetStatus,
                icon: Icons.flag_outlined,
                value: _selectedStatus,
                items: AssetStatus.values.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(_statusLabel(s)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedStatus = v!),
              ),
              const SizedBox(height: 24),

              // Section: Locație & Atribuire
              _SectionTitle(title: 'Locație & Atribuire'),
              const SizedBox(height: 14),

              _buildTextField(
                controller: _locationController,
                label: AppStrings.assetLocation,
                icon: Icons.location_on_outlined,
                required: true,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _assignedToController,
                label: 'Atribuit persoanei',
                icon: Icons.person_outline_rounded,
              ),
              const SizedBox(height: 24),

              // Section: Valoare & Dată
              _SectionTitle(title: 'Valoare & Dată Achiziție'),
              const SizedBox(height: 14),

              _buildTextField(
                controller: _valueController,
                label: '${AppStrings.assetValue} (RON)',
                icon: Icons.attach_money_rounded,
                keyboardType: TextInputType.number,
                required: true,
              ),
              const SizedBox(height: 16),

              // Date Picker
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.textHint, size: 20),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.assetPurchaseDate,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textHint,
                                  fontSize: 12,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormatter.format(_purchaseDate),
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textHint),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveAsset,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    AppStrings.save,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        filled: true,
        fillColor: AppColors.surface,
      ),
      validator: required
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Câmp obligatoriu';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textHint, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonFormField<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              dropdownColor: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ],
      ),
    );
  }

  String _categoryLabel(AssetCategory c) {
    switch (c) {
      case AssetCategory.electronics:
        return AppStrings.categoryElectronics;
      case AssetCategory.furniture:
        return AppStrings.categoryFurniture;
      case AssetCategory.vehicles:
        return AppStrings.categoryVehicles;
      case AssetCategory.equipment:
        return AppStrings.categoryEquipment;
      case AssetCategory.other:
        return AppStrings.categoryOther;
    }
  }

  String _statusLabel(AssetStatus s) {
    switch (s) {
      case AssetStatus.active:
        return AppStrings.statusActive;
      case AssetStatus.inRepair:
        return AppStrings.statusInRepair;
      case AssetStatus.decommissioned:
        return AppStrings.statusDecommissioned;
      case AssetStatus.transferred:
        return AppStrings.statusTransferred;
    }
  }

  void _saveAsset() {
    if (_formKey.currentState!.validate()) {
      // TODO: Trimite datele către bloc/repository
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bunul a fost adăugat cu succes!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      context.pop();
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

