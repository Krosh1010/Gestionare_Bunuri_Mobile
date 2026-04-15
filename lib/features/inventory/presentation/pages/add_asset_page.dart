import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/asset.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'barcode_scanner_page.dart';

class AddAssetPage extends StatefulWidget {
  const AddAssetPage({super.key});

  @override
  State<AddAssetPage> createState() => _AddAssetPageState();
}

class _AddAssetPageState extends State<AddAssetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();

  AssetCategory _selectedCategory = AssetCategory.electronics;
  DateTime _purchaseDate = DateTime.now();
  bool _isSaving = false;


  String? _scannedBarcode;

  // Spații – suport multi-nivel

  List<List<_SpaceItem>> _spaceLevels = [];

  List<_SpaceItem?> _selectedAtLevel = [];

  List<bool> _loadingAtLevel = [];

  bool _loadingParents = true;

  @override
  void initState() {
    super.initState();
    _loadParentSpaces();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _loadParentSpaces() async {
    try {
      final response = await sl<ApiClient>().dio.get('/Spaces/parents');
      final list = response.data as List;
      setState(() {
        final parents = list.map((json) => _SpaceItem.fromJson(json)).toList();
        _spaceLevels = [parents];
        _selectedAtLevel = [null];
        _loadingAtLevel = [false];
        _loadingParents = false;
      });
    } catch (e) {
      setState(() => _loadingParents = false);
    }
  }

  Future<void> _loadChildrenAtLevel(int level, String parentId) async {

    setState(() {

      if (_spaceLevels.length > level) {
        _spaceLevels = _spaceLevels.sublist(0, level);
        _selectedAtLevel = _selectedAtLevel.sublist(0, level);
        _loadingAtLevel = _loadingAtLevel.sublist(0, level);
      }

      _spaceLevels.add([]);
      _selectedAtLevel.add(null);
      _loadingAtLevel.add(true);
    });
    try {
      final response = await sl<ApiClient>().dio.get('/Spaces/children/$parentId');
      final list = response.data as List;
      setState(() {
        _spaceLevels[level] = list.map((json) => _SpaceItem.fromJson(json)).toList();
        _loadingAtLevel[level] = false;
      });
    } catch (e) {
      setState(() {
        _loadingAtLevel[level] = false;
      });
    }
  }


  int? get _selectedSpaceId {
    for (int i = _selectedAtLevel.length - 1; i >= 0; i--) {
      if (_selectedAtLevel[i] != null) return _selectedAtLevel[i]!.id;
    }
    return null;
  }


  String get _selectedSpacePath {
    final parts = <String>[];
    for (final s in _selectedAtLevel) {
      if (s != null) parts.add(s.name);
    }
    return parts.join(' → ');
  }

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

  Future<void> _saveAsset() async {
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
      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'category': _categoryToApiString(_selectedCategory),
        'value': double.tryParse(_valueController.text.trim()) ?? 0,
        'purchaseDate': _purchaseDate.toIso8601String(),
        'spaceId': _selectedSpaceId,
        if (_scannedBarcode != null && _scannedBarcode!.isNotEmpty)
          'barcode': _scannedBarcode,
      };

      final asset = await sl<InventoryRepository>().addAsset(data);

      if (mounted) {
        final assetId = int.tryParse(asset.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bunul a fost adăugat cu succes!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        // Navigăm către pagina post-salvare
        if (assetId != null) {
          final result = await context.push<bool>('/inventory/post-save/$assetId');
          if (mounted) context.pop(result ?? true);
        } else {
          context.pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la adăugare: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
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
              onPressed: _isSaving ? null : _saveAsset,
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
              // ─── Informații de bază ──────────────────────────
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

              // ─── Valoare & Dată ─────────────────────────────
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

              // ─── Spațiu ─────────────────────────────────────
              const _SectionTitle(title: 'Spațiu'),
              const SizedBox(height: 14),
              _buildSpaceSelector(),
              const SizedBox(height: 24),

              // ─── Cod de bare (opțional) ─────────────────────
              const _SectionTitle(title: 'Cod de bare (opțional)'),
              const SizedBox(height: 14),
              _buildBarcodeSection(),
              const SizedBox(height: 36),

              // ─── Buton Salvare ──────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAsset,
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
                          AppStrings.save,
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
    if (_loadingParents) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
            SizedBox(width: 12),
            Text('Se încarcă spațiile...', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    if (_spaceLevels.isEmpty || _spaceLevels[0].isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.textHint, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nu ai spații create. Creează un spațiu mai întâi.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Generăm dropdown-uri pentru fiecare nivel
        for (int level = 0; level < _spaceLevels.length; level++) ...[
          if (level > 0) const SizedBox(height: 16),
          Text(
            level == 0 ? 'Spațiu principal' : 'Sub-spațiu nivel ${level}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                  fontSize: 12,
                ),
          ),
          const SizedBox(height: 8),
          if (_loadingAtLevel[level])
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                  SizedBox(width: 12),
                  Text('Se încarcă sub-spațiile...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            )
          else
            _buildSpaceDropdown(
              items: _spaceLevels[level],
              selectedItem: _selectedAtLevel[level],
              hint: level == 0 ? 'Selectează spațiul principal...' : 'Selectează sub-spațiul...',
              showClearButton: level > 0 && _selectedAtLevel[level] != null,
              onChanged: (_SpaceItem? space) {
                final currentLevel = level;
                setState(() {
                  _selectedAtLevel[currentLevel] = space;

                  if (_spaceLevels.length > currentLevel + 1) {
                    _spaceLevels = _spaceLevels.sublist(0, currentLevel + 1);
                    _selectedAtLevel = _selectedAtLevel.sublist(0, currentLevel + 1);
                    _loadingAtLevel = _loadingAtLevel.sublist(0, currentLevel + 1);
                  }
                });

                if (space != null && space.childrenCount > 0) {
                  _loadChildrenAtLevel(currentLevel + 1, space.id.toString());
                }
              },
              onClear: level > 0
                  ? () {
                      final currentLevel = level;
                      setState(() {
                        _selectedAtLevel[currentLevel] = null;

                        if (_spaceLevels.length > currentLevel + 1) {
                          _spaceLevels = _spaceLevels.sublist(0, currentLevel + 1);
                          _selectedAtLevel = _selectedAtLevel.sublist(0, currentLevel + 1);
                          _loadingAtLevel = _loadingAtLevel.sublist(0, currentLevel + 1);
                        }
                      });
                    }
                  : null,
            ),
        ],


        if (_selectedSpaceId != null) ...[
          const SizedBox(height: 12),
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
        ],
      ],
    );
  }

  Widget _buildSpaceDropdown({
    required List<_SpaceItem> items,
    required _SpaceItem? selectedItem,
    required String hint,
    required ValueChanged<_SpaceItem?> onChanged,
    bool showClearButton = false,
    VoidCallback? onClear,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<_SpaceItem>(
                value: selectedItem,
                hint: Text(hint, style: const TextStyle(color: AppColors.textHint, fontSize: 14)),
                isExpanded: true,
                borderRadius: BorderRadius.circular(14),
                dropdownColor: AppColors.surface,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textHint),
                items: items.map((space) {
                  return DropdownMenuItem<_SpaceItem>(
                    value: space,
                    child: Row(
                      children: [
                        Text(space.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                space.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (space.childrenCount > 0)
                                Text(
                                  '${space.childrenCount} sub-spații',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textHint),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
          if (showClearButton && onClear != null)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(Icons.close_rounded, color: AppColors.textHint, size: 20),
              ),
            ),
        ],
      ),
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
          borderSide: BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider),
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


  // BARCODE SECTION

  Widget _buildBarcodeSection() {
    if (_scannedBarcode != null && _scannedBarcode!.isNotEmpty) {
      // Codul de bare a fost scanat – afișăm rezultatul
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.qr_code_rounded, color: AppColors.success, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cod de bare scanat',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _scannedBarcode!,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openBarcodeScanner,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Rescanează'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _scannedBarcode = null);
                    },
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Șterge'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Cod de bare nescanat – afișăm butonul de scanare
    return GestureDetector(
      onTap: _openBarcodeScanner,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.divider,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scanează cod de bare',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Apasă pentru a scana codul de bare al produsului',
                    style: TextStyle(
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Future<void> _openBarcodeScanner() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerPage(),
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        _scannedBarcode = result;
      });
    }
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


// SPACE ITEM MODEL (local, for the form)


class _SpaceItem {
  final int id;
  final String name;
  final String type;
  final int childrenCount;

  const _SpaceItem({
    required this.id,
    required this.name,
    required this.type,
    this.childrenCount = 0,
  });

  String get emoji {
    switch (type.toLowerCase()) {
      case 'home':
        return '🏠';
      case 'office':
        return '🏢';
      case 'room':
        return '🚪';
      case 'storage':
        return '📦';
      default:
        return '📍';
    }
  }

  static String _mapType(dynamic type) {
    if (type is int) {
      switch (type) {
        case 0:
          return 'home';
        case 1:
          return 'office';
        case 2:
          return 'room';
        case 3:
          return 'storage';
        default:
          return 'other';
      }
    }
    return type?.toString() ?? 'other';
  }

  factory _SpaceItem.fromJson(Map<String, dynamic> json) {
    return _SpaceItem(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      type: _mapType(json['type']),
      childrenCount: json['childrenCount'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is _SpaceItem && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

