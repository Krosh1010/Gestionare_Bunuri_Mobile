import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/asset.dart';
import '../../domain/repositories/inventory_repository.dart';
import 'warranty_form_sheet.dart';
import 'insurance_form_sheet.dart';
import 'custom_tracker_form_sheet.dart';

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

  late AssetCategory _selectedCategory;
  late DateTime _purchaseDate;
  bool _isSaving = false;
  late Asset _currentAsset;

  // Spații – suport multi-nivel
  List<List<_SpaceItem>> _spaceLevels = [];
  List<_SpaceItem?> _selectedAtLevel = [];
  List<bool> _loadingAtLevel = [];
  bool _loadingSpaces = true;

  @override
  void initState() {
    super.initState();
    _currentAsset = widget.asset;
    _nameController = TextEditingController(text: widget.asset.name);
    _descriptionController = TextEditingController(text: widget.asset.description ?? '');
    _valueController = TextEditingController(text: widget.asset.value.toStringAsFixed(0));
    _selectedCategory = widget.asset.category;
    _purchaseDate = widget.asset.purchaseDate;

    _loadSpacesForAsset();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  /// Încarcă arborele de spații pe baza path-ului curent al asset-ului
  Future<void> _loadSpacesForAsset() async {
    try {
      // 1. Încarcă părinții (nivel 0)
      final parentsResponse = await sl<ApiClient>().dio.get('/Spaces/parents');
      final parentsList = parentsResponse.data as List;
      final parents = parentsList.map((json) => _SpaceItem.fromJson(json as Map<String, dynamic>)).toList();

      if (widget.asset.spaceId == null) {
        setState(() {
          _spaceLevels = [parents];
          _selectedAtLevel = [null];
          _loadingAtLevel = [false];
          _loadingSpaces = false;
        });
        return;
      }

      // 2. Încarcă path-ul spațiului curent
      List<Map<String, dynamic>> pathResponse;
      try {
        pathResponse = await sl<InventoryRepository>().getSpacePath(widget.asset.spaceId!);
      } catch (_) {
        // Dacă path-ul nu poate fi încărcat, afișăm doar părinții
        setState(() {
          _spaceLevels = [parents];
          _selectedAtLevel = [null];
          _loadingAtLevel = [false];
          _loadingSpaces = false;
        });
        return;
      }

      if (pathResponse.isEmpty) {
        setState(() {
          _spaceLevels = [parents];
          _selectedAtLevel = [null];
          _loadingAtLevel = [false];
          _loadingSpaces = false;
        });
        return;
      }

      // 3. Reconstruim arborele pe baza path-ului
      _spaceLevels = [parents];
      _selectedAtLevel = [null];
      _loadingAtLevel = [false];

      for (int i = 0; i < pathResponse.length; i++) {
        final pathItem = _SpaceItem.fromJson(pathResponse[i]);

        // Caută elementul în lista de la nivelul curent
        final currentLevelItems = _spaceLevels[i];
        _SpaceItem? matchingItem;
        for (final item in currentLevelItems) {
          if (item.id == pathItem.id) {
            matchingItem = item;
            break;
          }
        }
        // Dacă nu-l găsim (caz rar), folosim item-ul din path
        matchingItem ??= pathItem;
        _selectedAtLevel[i] = matchingItem;

        // Încarcă copiii dacă nu e ultimul din path SAU dacă e ultimul dar are copii
        if (i < pathResponse.length - 1 || matchingItem.childrenCount > 0) {
          try {
            final childrenResponse = await sl<ApiClient>().dio.get('/Spaces/children/${matchingItem.id}');
            final childrenList = childrenResponse.data as List;
            final children = childrenList.map((json) => _SpaceItem.fromJson(json as Map<String, dynamic>)).toList();
            if (children.isNotEmpty) {
              _spaceLevels.add(children);
              _selectedAtLevel.add(null);
              _loadingAtLevel.add(false);
            }
          } catch (_) {
            break;
          }
        }
      }

      setState(() {
        _loadingSpaces = false;
      });
    } catch (e) {
      // Fallback: încarcă doar părinții
      try {
        final parentsResponse = await sl<ApiClient>().dio.get('/Spaces/parents');
        final parentsList = parentsResponse.data as List;
        final parents = parentsList.map((json) => _SpaceItem.fromJson(json as Map<String, dynamic>)).toList();
        setState(() {
          _spaceLevels = [parents];
          _selectedAtLevel = [null];
          _loadingAtLevel = [false];
          _loadingSpaces = false;
        });
      } catch (_) {
        setState(() => _loadingSpaces = false);
      }
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
        _spaceLevels[level] = list.map((json) => _SpaceItem.fromJson(json as Map<String, dynamic>)).toList();
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
      final data = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'category': _categoryToApiString(_selectedCategory),
        'value': double.tryParse(_valueController.text.trim()) ?? 0,
        'purchaseDate': _purchaseDate.toIso8601String(),
        'spaceId': _selectedSpaceId,
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

              // ─── Garanție, Asigurare & Urmărire ───────────────────────
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
                ],
              ),
              const SizedBox(height: 36),

              // ─── Buton Salvare ──────────────────────────────
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

  // ═══════════════════════════════════════════════════════════
  // ACTION CARD (for warranty / insurance)
  // ═══════════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════
  // CATEGORY SELECTOR
  // ═══════════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════
  // SPACE SELECTOR (hierarchical: multi-level)
  // ═══════════════════════════════════════════════════════════
  Widget _buildSpaceSelector() {
    if (_loadingSpaces) {
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
        for (int level = 0; level < _spaceLevels.length; level++) ...[
          if (level > 0) const SizedBox(height: 16),
          Text(
            level == 0 ? 'Spațiu principal' : 'Sub-spațiu nivel $level',
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

        // Afișare spațiu selectat
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
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.close_rounded, color: AppColors.textHint, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TEXT FIELD BUILDER
  // ═══════════════════════════════════════════════════════════
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

// ═══════════════════════════════════════════════════════════════════
// SECTION TITLE WIDGET
// ═══════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════
// SPACE ITEM MODEL (local, for the form)
// ═══════════════════════════════════════════════════════════════════

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

