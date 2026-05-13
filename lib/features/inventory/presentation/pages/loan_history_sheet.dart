import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/repositories/inventory_repository.dart';

class LoanHistorySheet extends StatefulWidget {
  final int assetId;

  const LoanHistorySheet({super.key, required this.assetId});

  @override
  State<LoanHistorySheet> createState() => _LoanHistorySheetState();
}

class _LoanHistorySheetState extends State<LoanHistorySheet> {
  bool _loading = true;
  List<Map<String, dynamic>> _history = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await sl<InventoryRepository>().getLoanHistory(widget.assetId);
      if (mounted) setState(() { _history = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  Future<void> _deleteLoan(int loanId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        title: const Text('Șterge înregistrarea',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text(
            'Ești sigur că vrei să ștergi această înregistrare din istoric?',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Șterge'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await sl<InventoryRepository>().deleteLoan(loanId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Înregistrarea a fost ștearsă.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Istoric Împrumuturi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                tooltip: 'Reîncarcă',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Content
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Nu s-a putut încărca istoricul.',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            )
          else if (_history.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Niciun împrumut în istoric',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 32),
                itemCount: _history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final loan = _history[index];
                  return _LoanHistoryCard(
                    loan: loan,
                    onDelete: () => _deleteLoan(loan['id'] as int),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _LoanHistoryCard extends StatefulWidget {
  final Map<String, dynamic> loan;
  final VoidCallback onDelete;

  const _LoanHistoryCard({required this.loan, required this.onDelete});

  @override
  State<_LoanHistoryCard> createState() => _LoanHistoryCardState();
}

class _LoanHistoryCardState extends State<_LoanHistoryCard> {
  static const _fileChannel = MethodChannel('com.example.gestionare_bunuri_mobile/file_handler');
  final Set<int> _downloadingIds = {};

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return 'application/pdf';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls': return 'application/vnd.ms-excel';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'txt': return 'text/plain';
      default: return 'application/octet-stream';
    }
  }

  Future<void> _downloadDocument(int docId, String fileName) async {
    setState(() => _downloadingIds.add(docId));
    try {
      final bytes = await sl<InventoryRepository>().downloadLoanDocument(docId);
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      final mimeType = _getMimeType(fileName);
      await _fileChannel.invokeMethod('saveAndOpenFile', {
        'filePath': filePath,
        'fileName': fileName,
        'mimeType': mimeType,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fișierul a fost salvat: $fileName'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la descărcare: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _downloadingIds.remove(docId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final dateFmt = DateFormat('dd.MM.yyyy');
    final isActive = loan['isActive'] as bool? ?? false;

    String fmtDate(String? raw) {
      if (raw == null) return '—';
      final dt = DateTime.tryParse(raw);
      return dt != null ? dateFmt.format(dt) : '—';
    }

    final loanedAt = fmtDate(loan['loanedAt'] as String?);
    final returnedAt = fmtDate(loan['returnedAt'] as String?);
    final condition = loan['condition'] as String? ?? '—';
    final conditionOnReturn = loan['conditionOnReturn'] as String?;
    final notes = loan['notes'] as String?;
    final loanedToName = loan['loanedToName'] as String? ?? '—';
    final documents = (loan['documents'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? AppColors.error.withValues(alpha: 0.35)
              : AppColors.divider.withValues(alpha: 0.6),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: name + status badge + delete
          Row(
            children: [
              const Icon(Icons.person_rounded, color: AppColors.textHint, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  loanedToName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isActive ? 'Activ' : 'Returnat',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isActive ? AppColors.error : AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onDelete,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error, size: 17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),
          // Date row
          Row(
            children: [
              _InfoChip(icon: Icons.login_rounded, label: 'Împrumutat', value: loanedAt),
              const SizedBox(width: 12),
              _InfoChip(
                icon: Icons.logout_rounded,
                label: 'Returnat',
                value: returnedAt,
                valueColor: isActive ? AppColors.textHint : AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Condition row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoChip(icon: Icons.info_outline_rounded, label: 'Stare inițială', value: condition),
              if (conditionOnReturn != null) ...[
                const SizedBox(width: 12),
                _InfoChip(
                    icon: Icons.assignment_turned_in_outlined,
                    label: 'Stare returnare',
                    value: conditionOnReturn),
              ],
            ],
          ),
          // Documents section
          if (documents.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_file_rounded, color: AppColors.textHint, size: 14),
                const SizedBox(width: 4),
                const Text(
                  'Documente',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textHint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...documents.map((doc) {
              final docId = doc['id'] as int;
              final fileName = doc['fileName'] as String? ?? 'document';
              final isDownloading = _downloadingIds.contains(docId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined,
                        color: AppColors.primary, size: 15),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: isDownloading
                          ? null
                          : () => _downloadDocument(docId, fileName),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: isDownloading
                            ? const Padding(
                                padding: EdgeInsets.all(6),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(Icons.download_rounded,
                                color: AppColors.primary, size: 16),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          if (notes != null && notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.notes_rounded, color: AppColors.textHint, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    notes,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.textHint),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

