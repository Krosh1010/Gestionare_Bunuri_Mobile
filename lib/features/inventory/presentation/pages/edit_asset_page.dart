import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/asset.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../widgets/space_picker_widget.dart';
import '../../../spaces/domain/entities/space.dart';
import 'barcode_scanner_page.dart';
import 'warranty_form_sheet.dart';
import 'insurance_form_sheet.dart';
import 'custom_tracker_form_sheet.dart';
import 'loan_form_sheet.dart';

class EditAssetPage extends StatefulWidget {
  final Asset asset;
  const EditAssetPage({super.key, required this.asset});

  @override
  State<EditAssetPage> createState() => _EditAssetPageState();
}

class _EditAssetPageState extends State<EditAssetPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _valueController;
  late final TextEditingController _barcodeController;

  late AssetCategory _selectedCategory;
  late DateTime _purchaseDate;
  bool _isSaving = false;
  late Asset _currentAsset;

  // Spațiu selectat via picker
  SelectedSpace? _selectedSpace;

  @override
  void initState() {
    super.initState();
    _currentAsset = widget.asset;
    _nameController = TextEditingController(text: widget.asset.name);
    _descriptionController = TextEditingController(text: widget.asset.description ?? '');
    _valueController = TextEditingController(text: widget.asset.value.toStringAsFixed(0));
    _barcodeController = TextEditingController(text: widget.asset.barcode ?? '');
    _selectedCategory = widget.asset.category;
    _purchaseDate = widget.asset.purchaseDate;

    // Inițializează spațiul selectat din asset
    if (widget.asset.spaceId != null) {
      _selectedSpace = SelectedSpace(
        id: widget.asset.spaceId!,
        name: widget.asset.spaceName ?? '',
        type: SpaceType.other, // Will be resolved by the picker when opened
        fullPath: widget.asset.spaceName,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  int? get _selectedSpaceId => _selectedSpace?.id;

  String get _selectedSpacePath => _selectedSpace?.fullPath ?? _selectedSpace?.name ?? '';

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
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

  String _categoryToApiString(AssetCategory c) {
    switch (c) {
      case AssetCategory.electronics:
        return 'electronics';
      case AssetCategory.furniture:
        return 'furniture';
      case AssetCategory.vehicles:
        return 'vehicles';
      case AssetCategory.documents:
        return 'documents';
      case AssetCategory.other:
        return 'other';
    }
  }

  String _categoryLabel(AssetCategory c) {
    switch (c) {
      case AssetCategory.electronics:
        return 'Electronică';
      case AssetCategory.furniture:
        return 'Mobilier';
      case AssetCategory.vehicles:
        return 'Vehicule';
      case AssetCategory.documents:
        return 'Documente';
      case AssetCategory.other:
        return 'Altele';
    }
  }

  String _categoryEmoji(AssetCategory c) {
    switch (c) {
      case AssetCategory.electronics:
        return '💻';
      case AssetCategory.furniture:
        return '🛋️';
      case AssetCategory.vehicles:
        return '🚗';
      case AssetCategory.documents:
        return '📄';
      case AssetCategory.other:
        return '📁';
    }
  }

  Future<void> _updateAsset() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSpaceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Te rog selectează un spațiu!'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final barcodeValue = _barcodeController.text.trim();
      final String? newBarcode = barcodeValue.isEmpty ? null : barcodeValue;

      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'category': _categoryToApiString(_selectedCategory),
        'value': double.tryParse(_valueController.text.trim()) ?? 0,
        'purchaseDate': _purchaseDate.toIso8601String(),
        'spaceId': _selectedSpaceId,
        'barcode': newBarcode,
        'barcodeIsSet': true,
      };

      await sl<InventoryRepository>().updateAsset(widget.asset.id, data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bunul a fost actualizat cu succes!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la actualizare: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _refreshAsset() async {
    try {
      final updated = await sl<InventoryRepository>().getAssetById(widget.asset.id);
      if (mounted) {
        setState(() => _currentAsset = updated);
      }
    } catch (_) {}
  }

  Future<void> _showWarrantySheet() async {
    final assetId = int.tryParse(widget.asset.id);
    if (assetId == null) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WarrantyFormSheet(assetId: assetId),
    );
    if (result == true && mounted) {
      await _refreshAsset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Garanția a fost actualizată!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _showInsuranceSheet() async {
    final assetId = int.tryParse(widget.asset.id);
    if (assetId == null) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InsuranceFormSheet(assetId: assetId),
    );
    if (result == true && mounted) {
      await _refreshAsset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Asigurarea a fost actualizată!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _showCustomTrackerSheet() async {
    final assetId = int.tryParse(widget.asset.id);
    if (assetId == null) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomTrackerFormSheet(assetId: assetId),
    );
    if (result == true && mounted) {
      await _refreshAsset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Urmărirea personalizată a fost actualizată!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _showLoanSheet() async {
    final assetId = int.tryParse(widget.asset.id);
    if (assetId == null) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LoanFormSheet(assetId: assetId),
    );
    if (result == true && mounted) {
      await _refreshAsset();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Împrumutul a fost actualizat!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _scanBarcodeForEdit() async {
    final barcode = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
    );
    if (barcode != null && barcode.isNotEmpty && mounted) {
      setState(() => _barcodeController.text = barcode);
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
        title: const Text(AppStrings.editAsset),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _isSaving ? null : _updateAsset,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )
                  : const Text(
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
              //  Informații de bază
              const _SectionTitle(title: 'Informații de bază'),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _nameController,
                label: AppStrings.assetName,
                icon: Icons.inventory_2_outlined,
                required: true,
              ),
              const SizedBox(height: 16),
              _buildCategorySelector(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: AppStrings.assetDescription,
                icon: Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Valoare & Dată
              const _SectionTitle(title: 'Valoare & Dată Achiziție'),
              const SizedBox(height: 14),
              _buildTextField(
                controller: _valueController,
                label: '${AppStrings.assetValue} (RON)',
                icon: Icons.attach_money_rounded,
                keyboardType: TextInputType.number,
                required: true,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),

              // Spațiu
              const _SectionTitle(title: 'Spațiu'),
              const SizedBox(height: 14),
              _buildSpaceSelector(),
              const SizedBox(height: 24),

              //  Cod de bare
              const _SectionTitle(title: 'Cod de bare'),
              const SizedBox(height: 14),
              _buildBarcodeField(),
              const SizedBox(height: 24),

              //  Garanție, Asigurare & Urmărire
              const _SectionTitle(title: 'Garanție, Asigurare & Urmărire'),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.verified_user_rounded,
                      label: 'Editează\nGaranție',
                      color: const Color(0xFF4F46E5),
                      statusLabel: _currentAsset.warrantyStatusLabel,
                      onTap: _showWarrantySheet,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.security_rounded,
                      label: 'Editează\nAsigurare',
                      color: const Color(0xFF22C55E),
                      statusLabel: _currentAsset.insuranceStatusLabel,
                      onTap: _showInsuranceSheet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.track_changes_rounded,
                      label: 'Editează\nUrmărire Personalizată',
                      color: const Color(0xFFFFA500),
                      statusLabel: _currentAsset.customTrackerStatusLabel,
                      onTap: _showCustomTrackerSheet,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.swap_horiz_rounded,
                      label: _currentAsset.isLoaned
                          ? 'Gestionează\nÎmprumut'
                          : 'Adaugă\nÎmprumut',
                      color: AppColors.error,
                      statusLabel: _currentAsset.isLoaned
                          ? 'Activ → ${_currentAsset.loanedToName ?? ''}'
                          : 'Niciun împrumut',
                      onTap: _showLoanSheet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              //  Buton Salvare
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _updateAsset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Actualizează',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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


  // BARCODE FIELD

  Widget _buildBarcodeField() {
    return StatefulBuilder(
      builder: (context, setLocal) {
        final hasBarcode = _barcodeController.text.isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasBarcode
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.4)
                  : AppColors.divider,
              width: hasBarcode ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code_rounded,
                        color: Color(0xFF8B5CF6), size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cod de bare',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          hasBarcode
                              ? _barcodeController.text
                              : 'Niciun cod asociat',
                          style: TextStyle(
                            fontSize: 12,
                            color: hasBarcode
                                ? const Color(0xFF8B5CF6)
                                : AppColors.textHint,
                            fontWeight: hasBarcode
                                ? FontWeight.w600
                                : FontWeight.w400,
                            letterSpacing: hasBarcode ? 1.0 : 0,
                            fontStyle: hasBarcode
                                ? FontStyle.normal
                                : FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Câmp text editabil
              TextFormField(
                controller: _barcodeController,
                onChanged: (_) => setLocal(() {}),
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
                decoration: InputDecoration(
                  hintText: 'Ex: 1234567890128',
                  hintStyle: const TextStyle(
                    color: AppColors.textHint,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                  ),
                  prefixIcon: const Icon(Icons.qr_code_2_rounded,
                      color: AppColors.textHint, size: 20),
                  suffixIcon: hasBarcode
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: AppColors.textHint, size: 20),
                          tooltip: 'Șterge codul',
                          onPressed: () {
                            _barcodeController.clear();
                            setLocal(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: AppColors.divider.withValues(alpha: 0.6)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: AppColors.divider.withValues(alpha: 0.6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: Color(0xFF8B5CF6), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              //  Buton scanare
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await _scanBarcodeForEdit();
                    setLocal(() {});
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                  label: const Text('Scanează cu camera'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5CF6),
                    side: BorderSide(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (hasBarcode) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                          title: const Row(
                            children: [
                              Icon(Icons.delete_outline_rounded,
                                  color: AppColors.error, size: 22),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Șterge codul de bare',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          content: const Text(
                            'Ești sigur că vrei să elimini codul de bare asociat acestui bun?',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 14),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Anulează'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _barcodeController.clear();
                                setLocal(() {});
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Șterge'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline_rounded,
                        size: 16, color: AppColors.error),
                    label: const Text('Elimină codul de bare',
                        style:
                            TextStyle(color: AppColors.error, fontSize: 13)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }


  // ACTION CARD (for warranty / insurance)

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required String statusLabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // CATEGORY SELECTOR

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.assetCategory,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textHint,
                fontSize: 12,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AssetCategory.values.map((cat) {
            final isSelected = _selectedCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_categoryEmoji(cat), style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      _categoryLabel(cat),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }


  // SPACE SELECTOR (hierarchical: multi-level)

  Widget _buildSpaceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedSpaceId != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedSpacePath,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        GestureDetector(
          onTap: () async {
            final space = await showDialog<SelectedSpace?>(
              context: context,
              builder: (context) => SpacePickerDialog(initialValue: _selectedSpace),
            );
            if (space != null) {
              setState(() {
                _selectedSpace = space;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedSpaceId != null ? 'Spațiu selectat' : 'Selectează un spațiu',
                        style: TextStyle(
                          color: _selectedSpaceId != null ? AppColors.textPrimary : AppColors.textHint,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedSpaceId != null
                            ? _selectedSpacePath
                            : 'Apasă pentru a alege un spațiu',
                        style: TextStyle(
                          color: _selectedSpaceId != null ? AppColors.textSecondary : AppColors.textHint,
                          fontSize: _selectedSpaceId != null ? 13 : 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ],
    );
  }


  // TEXT FIELD BUILDER

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
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Câmp obligatoriu';
              }
              return null;
            }
          : null,
    );
  }
}

// SECTION TITLE WIDGET


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
