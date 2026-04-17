import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/repositories/inventory_repository.dart';

// ─────────────────────────────────────────────────────────────────
// Sheet principal: gestionare împrumut (creare / editare / returnare / ștergere)
// ─────────────────────────────────────────────────────────────────
class LoanFormSheet extends StatefulWidget {
  final int assetId;

  const LoanFormSheet({super.key, required this.assetId});

  @override
  State<LoanFormSheet> createState() => _LoanFormSheetState();
}

class _LoanFormSheetState extends State<LoanFormSheet> {
  bool _loading = true;

  // Date împrumut existent (dacă există)
  Map<String, dynamic>? _activeLoan;

  @override
  void initState() {
    super.initState();
    _loadActiveLoan();
  }

  Future<void> _loadActiveLoan() async {
    try {
      final loan = await sl<InventoryRepository>()
          .getActiveLoanByAsset(widget.assetId);
      setState(() {
        _activeLoan = loan;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _activeLoan = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: _loading
          ? const SizedBox(
              height: 180,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          : _activeLoan != null
              ? _ActiveLoanView(
                  assetId: widget.assetId,
                  loan: _activeLoan!,
                  onDeleted: () => Navigator.pop(context, true),
                  onReturned: () => Navigator.pop(context, true),
                  onEdited: () => Navigator.pop(context, true),
                )
              : _CreateLoanView(
                  assetId: widget.assetId,
                  onCreated: () => Navigator.pop(context, true),
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Formular CREARE împrumut
// ─────────────────────────────────────────────────────────────────
class _CreateLoanView extends StatefulWidget {
  final int assetId;
  final VoidCallback onCreated;

  const _CreateLoanView({required this.assetId, required this.onCreated});

  @override
  State<_CreateLoanView> createState() => _CreateLoanViewState();
}

class _CreateLoanViewState extends State<_CreateLoanView> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _conditionCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _loanedAt = DateTime.now();
  bool _saving = false;
  List<File> _selectedDocuments = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _conditionCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _loanedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _loanedAt = picked);
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );
    if (result != null) {
      setState(() {
        _selectedDocuments.addAll(
          result.files
              .where((f) => f.path != null)
              .map((f) => File(f.path!)),
        );
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await sl<InventoryRepository>().createLoan(
        {
          'assetId': widget.assetId,
          'loanedToName': _nameCtrl.text.trim(),
          'condition': _conditionCtrl.text.trim(),
          'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          'loanedAt': _loanedAt.toIso8601String(),
        },
        documents: _selectedDocuments.isEmpty ? null : _selectedDocuments,
      );
      if (mounted) widget.onCreated();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
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
    final dateFmt = DateFormat('dd.MM.yyyy');
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.swap_horiz_rounded,
                      color: AppColors.error, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Adaugă Împrumut',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Nume persoană
            _LoanField(
              controller: _nameCtrl,
              label: 'Persoana împrumutată',
              icon: Icons.person_rounded,
              required: true,
              hint: 'Ex: Ion Popescu',
            ),
            const SizedBox(height: 14),
            // Stare la împrumut
            _LoanField(
              controller: _conditionCtrl,
              label: 'Stare la împrumut',
              icon: Icons.info_outline_rounded,
              required: true,
              hint: 'Ex: Bună stare, fără zgârieturi',
            ),
            const SizedBox(height: 14),
            // Data împrumutului
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: AppColors.textHint, size: 18),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Data împrumutului',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          dateFmt.format(_loanedAt),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_drop_down_rounded,
                        color: AppColors.textHint),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Note (opțional)
            _LoanField(
              controller: _notesCtrl,
              label: 'Note (opțional)',
              icon: Icons.notes_rounded,
              maxLines: 3,
              hint: 'Orice informații suplimentare...',
            ),
            const SizedBox(height: 14),
            // Documente (opțional)
            GestureDetector(
              onTap: _pickDocuments,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file_rounded,
                        color: AppColors.textHint, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Documente atașate (opțional)',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _selectedDocuments.isEmpty
                                ? 'Apasă pentru a selecta fișiere'
                                : '${_selectedDocuments.length} fișier(e) selectat(e)',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.add_rounded, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            // Lista fișierelor selectate
            if (_selectedDocuments.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...List.generate(_selectedDocuments.length, (i) {
                final fileName = _selectedDocuments[i].path.split(Platform.pathSeparator).last;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file_rounded, color: AppColors.textHint, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _selectedDocuments.removeAt(i)),
                          child: const Icon(Icons.close_rounded, color: AppColors.error, size: 18),
                        ),
                      ],
                    ),
                  ),
                );
             }),
            ],
            const SizedBox(height: 24),
            // Buton Salvare
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check_rounded,
                        color: Colors.white, size: 20),
                label: Text(
                  _saving ? 'Se salvează...' : 'Salvează Împrumut',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// View împrumut ACTIV (editare / returnare / ștergere)
// ─────────────────────────────────────────────────────────────────
class _ActiveLoanView extends StatefulWidget {
  final int assetId;
  final Map<String, dynamic> loan;
  final VoidCallback onDeleted;
  final VoidCallback onReturned;
  final VoidCallback onEdited;

  const _ActiveLoanView({
    required this.assetId,
    required this.loan,
    required this.onDeleted,
    required this.onReturned,
    required this.onEdited,
  });

  @override
  State<_ActiveLoanView> createState() => _ActiveLoanViewState();
}

class _ActiveLoanViewState extends State<_ActiveLoanView> {
  // Tab: 0 = info+editare, 1 = returnare
  int _tab = 0;

  // Edit controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _conditionCtrl;
  late final TextEditingController _notesCtrl;
  late DateTime _loanedAt;

  // Return controllers
  final _returnConditionCtrl = TextEditingController();
  final _returnNotesCtrl = TextEditingController();
  DateTime _returnedAt = DateTime.now();

  bool _saving = false;

  // Documents
  List<Map<String, dynamic>> _existingDocuments = [];
  List<File> _newDocuments = [];
  bool _isDownloading = false;
  static const _fileChannel = MethodChannel('com.example.gestionare_bunuri_mobile/file_handler');

  int get _loanId => widget.loan['loanId'] as int? ?? widget.loan['id'] as int;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.loan['loanedToName'] as String? ?? '');
    _conditionCtrl = TextEditingController(
        text: widget.loan['condition'] as String? ?? '');
    _notesCtrl = TextEditingController(
        text: widget.loan['notes'] as String? ?? '');
    final rawDate = widget.loan['loanedAt'] as String?;
    _loanedAt =
        rawDate != null ? DateTime.tryParse(rawDate) ?? DateTime.now() : DateTime.now();
    // Load existing documents from loan data
    final docs = widget.loan['documents'];
    if (docs is List) {
      _existingDocuments = docs.map((d) => Map<String, dynamic>.from(d as Map)).toList();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _conditionCtrl.dispose();
    _notesCtrl.dispose();
    _returnConditionCtrl.dispose();
    _returnNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isReturn) async {
    final initial = isReturn ? _returnedAt : _loanedAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isReturn) {
          _returnedAt = picked;
        } else {
          _loanedAt = picked;
        }
      });
    }
  }

  Future<void> _pickNewDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
    );
    if (result != null) {
      setState(() {
        _newDocuments.addAll(
          result.files.where((f) => f.path != null).map((f) => File(f.path!)),
        );
      });
    }
  }

  Future<void> _saveEdit() async {
    if (_nameCtrl.text.trim().isEmpty || _conditionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Completează câmpurile obligatorii!'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await sl<InventoryRepository>().updateLoan(
        _loanId,
        {
          'loanedToName': _nameCtrl.text.trim(),
          'condition': _conditionCtrl.text.trim(),
          'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          'loanedAt': _loanedAt.toIso8601String(),
        },
        documents: _newDocuments.isEmpty ? null : _newDocuments,
      );
      if (mounted) widget.onEdited();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showError('$e');
      }
    }
  }

  Future<void> _saveReturn() async {
    if (_returnConditionCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Introdu starea la returnare!'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await sl<InventoryRepository>().returnLoan(_loanId, {
        'conditionOnReturn': _returnConditionCtrl.text.trim(),
        'returnedAt': _returnedAt.toIso8601String(),
        'notes': _returnNotesCtrl.text.trim().isEmpty
            ? null
            : _returnNotesCtrl.text.trim(),
      });
      if (mounted) widget.onReturned();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showError('$e');
      }
    }
  }

  Future<void> _deleteLoan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
        title: const Text('Șterge împrumutul',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
        content: const Text(
            'Ești sigur că vrei să ștergi acest împrumut? Acțiunea nu poate fi anulată.',
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
    setState(() => _saving = true);
    try {
      await sl<InventoryRepository>().deleteLoan(_loanId);
      if (mounted) widget.onDeleted();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        _showError('$e');
      }
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

  Future<void> _downloadDocument(int docId, String fileName) async {
    setState(() => _isDownloading = true);
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
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError('Eroare la descărcare: $e');
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _deleteDocument(int docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Șterge Documentul'),
        content: const Text('Ești sigur că vrei să ștergi acest document?'),
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
    try {
      await sl<InventoryRepository>().deleteLoanDocument(docId);
      if (mounted) {
        setState(() {
          _existingDocuments.removeWhere((d) => d['id'] == docId);
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
      if (mounted) _showError('Eroare la ștergere: $e');
    }
  }

  Future<void> _deleteAllDocuments() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Șterge Toate Documentele'),
        content: const Text('Ești sigur că vrei să ștergi toate documentele atașate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anulează'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Șterge Toate', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await sl<InventoryRepository>().deleteAllLoanDocuments(_loanId);
      if (mounted) {
        setState(() => _existingDocuments.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Toate documentele au fost șterse!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showError('Eroare: $e');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Eroare: $msg'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd.MM.yyyy');

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.swap_horiz_rounded,
                    color: AppColors.error, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Împrumut activ',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Către: ${widget.loan['loanedToName'] ?? '—'}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Buton ștergere
              IconButton(
                onPressed: _saving ? null : _deleteLoan,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                tooltip: 'Șterge împrumut',
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.error.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Tab Selector
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                _TabBtn(
                  label: 'Editează',
                  icon: Icons.edit_rounded,
                  active: _tab == 0,
                  onTap: () => setState(() => _tab = 0),
                ),
                const SizedBox(width: 4),
                _TabBtn(
                  label: 'Înregistrează Returnare',
                  icon: Icons.assignment_return_rounded,
                  active: _tab == 1,
                  color: AppColors.success,
                  onTap: () => setState(() => _tab = 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── TAB 0: Editare ──
          if (_tab == 0) ...[
            _LoanField(
              controller: _nameCtrl,
              label: 'Persoana împrumutată',
              icon: Icons.person_rounded,
              required: true,
              hint: 'Ex: Ion Popescu',
            ),
            const SizedBox(height: 14),
            _LoanField(
              controller: _conditionCtrl,
              label: 'Stare la împrumut',
              icon: Icons.info_outline_rounded,
              required: true,
              hint: 'Ex: Bună stare',
            ),
            const SizedBox(height: 14),
            // Data împrumutului
            GestureDetector(
              onTap: () => _pickDate(false),
              child: _DateRow(
                  label: 'Data împrumutului', date: dateFmt.format(_loanedAt)),
            ),
            const SizedBox(height: 14),
            _LoanField(
              controller: _notesCtrl,
              label: 'Note (opțional)',
              icon: Icons.notes_rounded,
              maxLines: 3,
              hint: 'Informații suplimentare...',
            ),
            const SizedBox(height: 14),
            // Documente existente
            if (_existingDocuments.isNotEmpty) ...[
              Row(
                children: [
                  const Text(
                    'Documente existente',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _saving ? null : _deleteAllDocuments,
                    icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: AppColors.error),
                    label: const Text('Șterge toate', style: TextStyle(color: AppColors.error, fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._existingDocuments.map((doc) {
                final fileName = doc['fileName'] as String? ?? 'Fișier necunoscut';
                final docId = doc['id'] as int? ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file_rounded, color: AppColors.textHint, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          onPressed: _isDownloading ? null : () => _downloadDocument(docId, fileName),
                          icon: Icon(
                            _isDownloading ? Icons.hourglass_empty : Icons.download_rounded,
                            color: _isDownloading ? AppColors.textHint : AppColors.primary,
                            size: 18,
                          ),
                          tooltip: 'Descarcă fișierul',
                        ),
                        IconButton(
                          onPressed: _saving ? null : () => _deleteDocument(docId),
                          icon: const Icon(Icons.delete_rounded, color: AppColors.error, size: 18),
                          tooltip: 'Șterge fișierul',
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
            const SizedBox(height: 14),
            // Documente noi (opțional)
            GestureDetector(
              onTap: _pickNewDocuments,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file_rounded,
                        color: AppColors.textHint, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Documente noi (opțional)',
                            style: TextStyle(
                              color: AppColors.textHint,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _newDocuments.isEmpty
                                ? 'Apasă pentru a selecta fișiere'
                                : '${_newDocuments.length} fișier(e) selectat(e)',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.add_rounded, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            // Lista fișierelor noi selectate
            if (_newDocuments.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...List.generate(_newDocuments.length, (i) {
                final fileName = _newDocuments[i].path.split(Platform.pathSeparator).last;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file_rounded, color: AppColors.textHint, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            fileName,
                            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _newDocuments.removeAt(i)),
                          child: const Icon(Icons.close_rounded, color: AppColors.error, size: 18),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveEdit,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded,
                        color: Colors.white, size: 20),
                label: Text(
                  _saving ? 'Se salvează...' : 'Salvează Modificările',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],

          // ── TAB 1: Returnare ──
          if (_tab == 1) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Înregistrează returnarea bunului de la "${widget.loan['loanedToName'] ?? ''}".',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _LoanField(
              controller: _returnConditionCtrl,
              label: 'Stare la returnare',
              icon: Icons.assignment_turned_in_outlined,
              required: true,
              hint: 'Ex: Bună stare, fără deteriorări',
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => _pickDate(true),
              child: _DateRow(
                  label: 'Data returnării', date: dateFmt.format(_returnedAt)),
            ),
            const SizedBox(height: 14),
            _LoanField(
              controller: _returnNotesCtrl,
              label: 'Note returnare (opțional)',
              icon: Icons.notes_rounded,
              maxLines: 3,
              hint: 'Informații suplimentare...',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveReturn,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.assignment_return_rounded,
                        color: Colors.white, size: 20),
                label: Text(
                  _saving ? 'Se salvează...' : 'Confirmă Returnarea',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Widgets helper
// ─────────────────────────────────────────────────────────────────

class _LoanField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool required;
  final int maxLines;
  final String? hint;

  const _LoanField({
    required this.controller,
    required this.label,
    required this.icon,
    this.required = false,
    this.maxLines = 1,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.textHint, size: 20),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.divider.withValues(alpha: 0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Câmp obligatoriu' : null
          : null,
    );
  }
}

class _DateRow extends StatelessWidget {
  final String label;
  final String date;

  const _DateRow({required this.label, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded,
              color: AppColors.textHint, size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                date,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.arrow_drop_down_rounded, color: AppColors.textHint),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _TabBtn({
    required this.label,
    required this.icon,
    required this.active,
    this.color = AppColors.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16, color: active ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
