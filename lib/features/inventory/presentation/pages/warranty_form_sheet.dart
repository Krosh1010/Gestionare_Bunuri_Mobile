import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/repositories/inventory_repository.dart';

class WarrantyFormSheet extends StatefulWidget {
  final int assetId;
  const WarrantyFormSheet({super.key, required this.assetId});

  @override
  State<WarrantyFormSheet> createState() => _WarrantyFormSheetState();
}

class _WarrantyFormSheetState extends State<WarrantyFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _providerController = TextEditingController();
  static const _fileChannel = MethodChannel('com.example.gestionare_bunuri_mobile/file_handler');
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 365));
  bool _isSaving = false;
  bool _isLoading = true;
  bool _hasExisting = false;
  bool _isDeleting = false;

  // Document
  File? _selectedDocument;
  String? _existingDocumentFileName;
  bool _isDeletingDocument = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingWarranty();
  }

  Future<void> _loadExistingWarranty() async {
    try {
      final data = await sl<InventoryRepository>().getWarrantyByAsset(widget.assetId);
      if (data != null && mounted) {
        setState(() {
          _hasExisting = true;
          _providerController.text = data['provider'] as String? ?? '';
          if (data['startDate'] != null) {
            _startDate = DateTime.tryParse(data['startDate'].toString()) ?? _startDate;
          }
          if (data['endDate'] != null) {
            _endDate = DateTime.tryParse(data['endDate'].toString()) ?? _endDate;
          }
          _existingDocumentFileName = data['documentFileName'] as String?;
          _isLoading = false;
        });
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _providerController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2040),
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
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedDocument = File(result.files.single.path!);
      });
    }
  }

  Future<void> _downloadDocument() async {
    setState(() => _isDownloading = true);
    try {
      final bytes = await sl<InventoryRepository>().downloadWarrantyDocument(widget.assetId);
      final fileName = _existingDocumentFileName ?? 'warranty_document';

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
            content: Text('Fișierul a fost salvat în Descărcări: $fileName'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

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

  Future<void> _deleteDocument() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Șterge Documentul'),
        content: const Text('Ești sigur că vrei să ștergi documentul atașat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Șterge', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isDeletingDocument = true);
    try {
      await sl<InventoryRepository>().deleteWarrantyDocument(widget.assetId);
      if (mounted) {
        setState(() {
          _existingDocumentFileName = null;
          _isDeletingDocument = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Documentul a fost șters!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeletingDocument = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la ștergerea documentului: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  String _formatDate(DateTime d) => DateFormat('dd.MM.yyyy').format(d);
  String _apiDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final payload = {
        'assetId': widget.assetId,
        'provider': _providerController.text.trim(),
        'startDate': _apiDate(_startDate),
        'endDate': _apiDate(_endDate),
      };

      if (_hasExisting) {
        await sl<InventoryRepository>().updateWarrantyByAsset(
          widget.assetId,
          payload,
          document: _selectedDocument,
        );
      } else {
        await sl<InventoryRepository>().addWarranty(
          payload,
          document: _selectedDocument,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Șterge Garanția'),
        content: const Text('Ești sigur că vrei să ștergi garanția acestui bun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Șterge', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      await sl<InventoryRepository>().deleteWarrantyByAsset(widget.assetId);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Eroare la ștergere: $e'),
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
              ),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.divider,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.verified_user_rounded, color: Color(0xFF4F46E5), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _hasExisting ? 'Editează Garanție' : 'Adaugă Garanție',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Furnizor
                    TextFormField(
                      controller: _providerController,
                      decoration: InputDecoration(
                        labelText: 'Furnizor',
                        prefixIcon: const Icon(Icons.store_rounded, color: AppColors.textHint, size: 20),
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
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Câmp obligatoriu' : null,
                    ),
                    const SizedBox(height: 16),

                    // Data început
                    _buildDateTile(
                      label: 'Data început',
                      date: _startDate,
                      onTap: () => _pickDate(true),
                    ),
                    const SizedBox(height: 12),

                    // Data expirare
                    _buildDateTile(
                      label: 'Data expirare',
                      date: _endDate,
                      onTap: () => _pickDate(false),
                    ),
                    const SizedBox(height: 16),

                    // Document section
                    _buildDocumentSection(),
                    const SizedBox(height: 28),

                    // Salvare
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_isSaving || _isDeleting) ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          disabledBackgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                _hasExisting ? 'Actualizează Garanția' : 'Salvează Garanția',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                      ),
                    ),
                    if (_hasExisting) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: (_isSaving || _isDeleting) ? null : _delete,
                          icon: _isDeleting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                                )
                              : const Icon(Icons.delete_rounded, color: AppColors.error),
                          label: Text(
                            _isDeleting ? 'Se șterge...' : 'Șterge Garanția',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDocumentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attach_file_rounded, color: AppColors.textHint, size: 20),
              const SizedBox(width: 8),
              Text(
                'Document atașat',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'opțional',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Existing document on server
          if (_existingDocumentFileName != null && _selectedDocument == null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.description_rounded, color: Color(0xFF4F46E5), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _existingDocumentFileName!,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF4F46E5)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isDownloading ? null : _downloadDocument,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                          )
                        : const Icon(Icons.download_rounded, size: 18),
                    label: Text(_isDownloading ? 'Se descarcă...' : 'Descarcă'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4F46E5),
                      side: const BorderSide(color: Color(0xFF4F46E5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isDeletingDocument ? null : _deleteDocument,
                    icon: _isDeletingDocument
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.error),
                          )
                        : const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(_isDeletingDocument ? 'Se șterge...' : 'Șterge'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDocument,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Înlocuiește'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ]
          // Newly selected document
          else if (_selectedDocument != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedDocument!.path.split(Platform.pathSeparator).last,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _selectedDocument = null),
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textHint),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ]
          // No document
          else ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _pickDocument,
                icon: const Icon(Icons.upload_file_rounded, size: 20),
                label: const Text('Selectează document'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateTile({required String label, required DateTime date, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded, color: AppColors.textHint, size: 18),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                const SizedBox(height: 2),
                Text(
                  _formatDate(date),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
