import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import 'warranty_form_sheet.dart';
import 'insurance_form_sheet.dart';
import 'custom_tracker_form_sheet.dart';

class PostSaveMenuPage extends StatefulWidget {
  final int assetId;
  const PostSaveMenuPage({super.key, required this.assetId});

  @override
  State<PostSaveMenuPage> createState() => _PostSaveMenuPageState();
}

class _PostSaveMenuPageState extends State<PostSaveMenuPage> {
  bool _warrantyAdded = false;
  bool _insuranceAdded = false;
  bool _customTrackerAdded = false;

  void _finalize() {
    context.pop(true);
  }

  Future<void> _showWarrantyForm() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WarrantyFormSheet(assetId: widget.assetId),
    );
    if (result == true && mounted) {
      setState(() => _warrantyAdded = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Garanția a fost adăugată cu succes!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _showInsuranceForm() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InsuranceFormSheet(assetId: widget.assetId),
    );
    if (result == true && mounted) {
      setState(() => _insuranceAdded = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Asigurarea a fost adăugată cu succes!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _showCustomTrackerForm() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomTrackerFormSheet(assetId: widget.assetId),
    );
    if (result == true && mounted) {
      setState(() => _customTrackerAdded = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Custom Tracker a fost adăugat cu succes!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(true),
        ),
        title: const Text('Bun adăugat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Success icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'Bunul a fost adăugat!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dorești să adaugi garanție, asigurare sau custom tracker?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Adaugă Garanție
            _buildMenuOption(
              icon: Icons.verified_user_rounded,
              title: 'Adaugă Garanție',
              subtitle: _warrantyAdded ? 'Garanție adăugată ✓' : 'Furnizor, dată început și expirare',
              color: const Color(0xFF4F46E5),
              isCompleted: _warrantyAdded,
              onTap: _showWarrantyForm,
            ),
            const SizedBox(height: 16),

            // Adaugă Asigurare
            _buildMenuOption(
              icon: Icons.security_rounded,
              title: 'Adaugă Asigurare',
              subtitle: _insuranceAdded ? 'Asigurare adăugată ✓' : 'Companie, valoare, perioadă',
              color: const Color(0xFF22C55E),
              isCompleted: _insuranceAdded,
              onTap: _showInsuranceForm,
            ),
            const SizedBox(height: 16),

            // Adaugă Custom Tracker
            _buildMenuOption(
              icon: Icons.track_changes_rounded,
              title: 'Adaugă Custom Tracker',
              subtitle: _customTrackerAdded ? 'Tracker adăugat ✓' : 'Nume, descriere, perioadă',
              color: const Color(0xFFFF6B35),
              isCompleted: _customTrackerAdded,
              onTap: _showCustomTrackerForm,
            ),

            const Spacer(),

            // Finalizare
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _finalize,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Finalizare',
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
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted ? color.withValues(alpha: 0.4) : AppColors.divider,
            width: isCompleted ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isCompleted ? Icons.check_rounded : icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isCompleted ? color : AppColors.textSecondary,
                      fontWeight: isCompleted ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textHint,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
