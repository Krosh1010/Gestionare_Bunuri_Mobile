import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/repositories/inventory_repository.dart';
import '../widgets/space_picker_widget.dart';
import '../../../spaces/domain/entities/space.dart';

class InsuranceFormSheet extends StatefulWidget {
  final int assetId;
  const InsuranceFormSheet({super.key, required this.assetId});

  @override
  State<InsuranceFormSheet> createState() => _InsuranceFormSheetState();
}

class _InsuranceFormSheetState extends State<InsuranceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _valueController = TextEditingController();
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

  // Space
  SelectedSpace? _selectedSpace;
  bool _spaceChanged = false;

  @override
  void initState() {
    super.initState();
    _loadExistingInsurance();
  }

  Future<void> _loadExistingInsurance() async {
    try {
      final data = await sl<InventoryRepository>().getInsuranceByAsset(widget.assetId);
      if (data != null && mounted) {
        setState(() {
          _hasExisting = true;
          _companyController.text = data['company'] as String? ?? '';
          final insuredValue = data['insuredValue'];
          if (insuredValue != null) {
            _valueController.text = (insuredValue as num).toStringAsFixed(0);
          }
          if (data['startDate'] != null) {
            _startDate = DateTime.tryParse(data['startDate'].toString()) ?? _startDate;
          }
          if (data['endDate'] != null) {
            _endDate = DateTime.tryParse(data['endDate'].toString()) ?? _endDate;
          }
          _existingDocumentFileName = data['documentFileName'] as String?;
          // Space
          final spaceId = data['spaceId'] as int?;
          final spaceName = data['spaceName'] as String?;
          if (spaceId != null) {
            _selectedSpace = SelectedSpace(
              id: spaceId,
              name: spaceName ?? 'Spațiu #$spaceId',
              type: SpaceType.other,
              fullPath: spaceName,
            );
          }
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
    _companyController.dispose();
    _valueController.dispose();
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
      final bytes = await sl<InventoryRepository>().downloadInsuranceDocument(widget.assetId);
      final fileName = _existingDocumentFileName ?? 'insurance_document';

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
      await sl<InventoryRepository>().deleteInsuranceDocument(widget.assetId);
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
      final payload = <String, dynamic>{
        'assetId': widget.assetId,
        'company': _companyController.text.trim(),
        'insuredValue': double.tryParse(_valueController.text.trim()) ?? 0,
        'startDate': _apiDate(_startDate),
        'endDate': _apiDate(_endDate),
      };

      if (_hasExisting) {
        // For update, send spaceIdIsSet flag
        if (_spaceChanged) {
          payload['spaceIdIsSet'] = true;
          payload['spaceId'] = _selectedSpace?.id;
        }
        await sl<InventoryRepository>().updateInsuranceByAsset(
          widget.assetId,
          payload,
          document: _selectedDocument,
        );
      } else {
        // For create, send spaceId if selected
        if (_selectedSpace != null) {
          payload['spaceId'] = _selectedSpace!.id;
        }
        await sl<InventoryRepository>().addInsurance(
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
        title: const Text('Șterge Asigurarea'),
        content: const Text('Ești sigur că vrei să ștergi asigurarea acestui bun?'),
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
      await sl<InventoryRepository>().deleteInsuranceByAsset(widget.assetId);
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

  Widget _buildSpaceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedSpace != null) ...[
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
                    _selectedSpace!.fullPath ?? _selectedSpace!.name,
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
                _spaceChanged = true;
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
                        _selectedSpace != null ? 'Spațiu selectat' : 'Selectează un spațiu',
                        style: TextStyle(
                          color: _selectedSpace != null ? AppColors.textPrimary : AppColors.textHint,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_selectedSpace != null)
                        Text(
                          _selectedSpace!.fullPath ?? _selectedSpace!.name,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        )
                      else
                        Text(
                          'Apasă pentru a alege un spațiu (opțional)',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_selectedSpace != null)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedSpace = null;
                        _spaceChanged = true;
                      });
                    },
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textHint),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                else
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
              ],
            ),
          ),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_hasExisting ? 'Editează Asigurarea' : 'Adaugă Asigurare'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_hasExisting)
            IconButton(
              onPressed: _isDeleting ? null : _delete,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              tooltip: 'Șterge asigurarea',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company
                const Text('Companie asigurări', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _companyController,
                  decoration: InputDecoration(
                    hintText: 'Numele companiei de asigurări',
                    prefixIcon: const Icon(Icons.business_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Câmp obligatoriu' : null,
                ),
                const SizedBox(height: 20),

                // Insured value
                const Text('Valoare asigurată', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _valueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Valoare asigurată (MDL)',
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Câmp obligatoriu' : null,
                ),
                const SizedBox(height: 20),

                // Dates
                const Text('Perioada asigurării', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildDateTile(label: 'De la', date: _startDate, onTap: () => _pickDate(true))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDateTile(label: 'Până la', date: _endDate, onTap: () => _pickDate(false))),
                  ],
                ),
                const SizedBox(height: 20),

                // Space
                const Text('Spațiu (opțional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                _buildSpaceSelector(),
                const SizedBox(height: 20),

                // Document
                const Text('Document (opțional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                if (_existingDocumentFileName != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file_rounded, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _existingDocumentFileName!,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: _isDownloading ? null : _downloadDocument,
                          icon: _isDownloading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.download_rounded, size: 20),
                        ),
                        IconButton(
                          onPressed: _isDeletingDocument ? null : _deleteDocument,
                          icon: _isDeletingDocument
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_selectedDocument != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file_rounded, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedDocument!.path.split(Platform.pathSeparator).last,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _selectedDocument = null),
                          icon: const Icon(Icons.close_rounded, size: 20),
                        ),
                      ],
                    ),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _pickDocument,
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('Încarcă document'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                const SizedBox(height: 32),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            _hasExisting ? 'Salvează modificările' : 'Adaugă asigurarea',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
