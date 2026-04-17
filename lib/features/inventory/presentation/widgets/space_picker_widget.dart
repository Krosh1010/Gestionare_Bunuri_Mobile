import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../spaces/domain/entities/space.dart';
import '../../../spaces/domain/repositories/spaces_repository.dart';

/// A selected space value used by the picker.
class SelectedSpace {
  final int id;
  final String name;
  final SpaceType type;
  final String? fullPath;

  const SelectedSpace({
    required this.id,
    required this.name,
    required this.type,
    this.fullPath,
  });
}

/// Combined space picker with text search + tree browser.
class SpacePickerWidget extends StatefulWidget {
  final SelectedSpace? initialValue;
  final ValueChanged<SelectedSpace?> onChanged;

  const SpacePickerWidget({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<SpacePickerWidget> createState() => _SpacePickerWidgetState();
}

class _SpacePickerWidgetState extends State<SpacePickerWidget> {
  SelectedSpace? _selected;
  bool _showSearch = false;
  bool _showTree = false;

  // Search
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Space>? _searchResults;
  bool _searching = false;

  // Tree
  List<_TreeNode> _rootNodes = [];
  bool _loadingRoots = false;
  bool _treeLoaded = false;

  // For auto-expand on edit
  bool _autoExpandDone = false;

  SpacesRepository get _repo => sl<SpacesRepository>();

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _selectSpace(Space space, {String? computedFullPath}) {
    final sel = SelectedSpace(
      id: space.id,
      name: space.name,
      type: space.type,
      fullPath: space.fullPath ?? computedFullPath ?? space.name,
    );
    setState(() {
      _selected = sel;
      // Nu închidem dropdown-ul — utilizatorul poate continua să caute
    });
    widget.onChanged(sel);
  }

  void _clearSelection() {
    setState(() {
      _selected = null;
      _showSearch = false;
      _showTree = false;
    });
    widget.onChanged(null);
  }

  // ── Search ──

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() {
        _searchResults = null;
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await _repo.searchSpaces(query.trim());
        if (mounted && _searchController.text.trim() == query.trim()) {
          setState(() {
            _searchResults = results;
            _searching = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _searching = false);
      }
    });
  }

  // ── Tree ──

  Future<void> _loadRoots() async {
    if (_treeLoaded) return;
    setState(() => _loadingRoots = true);
    try {
      final roots = await _repo.getParentSpaces();
      setState(() {
        _rootNodes = roots.map((s) => _TreeNode(space: s)).toList();
        _loadingRoots = false;
        _treeLoaded = true;
      });
      // Auto-expand to selected space if editing
      if (_selected != null && !_autoExpandDone) {
        _autoExpandDone = true;
        await _autoExpandToSpace(_selected!.id);
      }
    } catch (_) {
      setState(() => _loadingRoots = false);
    }
  }

  Future<void> _autoExpandToSpace(int spaceId) async {
    try {
      final pathSpaces = await _repo.getSpacePath(spaceId);
      if (pathSpaces.isEmpty || !mounted) return;

      List<_TreeNode> currentLevel = _rootNodes;
      for (int i = 0; i < pathSpaces.length; i++) {
        final pathSpace = pathSpaces[i];
        final nodeIndex = currentLevel.indexWhere((n) => n.space.id == pathSpace.id);
        if (nodeIndex == -1) break;

        final node = currentLevel[nodeIndex];
        if (i < pathSpaces.length - 1) {
          // Need to expand this node
          if (!node.childrenLoaded) {
            node.loadingChildren = true;
            setState(() {});
            try {
              final children = await _repo.getChildrenSpaces(node.space.id);
              node.children = children.map((s) => _TreeNode(space: s)).toList();
              node.childrenLoaded = true;
            } catch (_) {}
            node.loadingChildren = false;
          }
          node.expanded = true;
          setState(() {});
          currentLevel = node.children;
        }
      }
    } catch (_) {}
  }

  Future<void> _toggleNode(_TreeNode node) async {
    if (node.expanded) {
      setState(() => node.expanded = false);
      return;
    }
    if (!node.childrenLoaded && node.space.childrenCount > 0) {
      setState(() => node.loadingChildren = true);
      try {
        final children = await _repo.getChildrenSpaces(node.space.id);
        node.children = children.map((s) => _TreeNode(space: s)).toList();
        node.childrenLoaded = true;
      } catch (_) {}
      if (mounted) setState(() => node.loadingChildren = false);
    }
    setState(() => node.expanded = true);
  }

  /// Construiește fullPath din arbore parcurgând nodurile rădăcină recursiv
  String _buildPathForNode(_TreeNode targetNode, List<_TreeNode> nodes, String prefix) {
    for (final node in nodes) {
      final currentPath = prefix.isEmpty ? node.space.name : '$prefix > ${node.space.name}';
      if (node.space.id == targetNode.space.id) {
        return currentPath;
      }
      if (node.expanded && node.childrenLoaded) {
        final found = _buildPathForNode(targetNode, node.children, currentPath);
        if (found.isNotEmpty) return found;
      }
    }
    return '';
  }

  // ── UI ──

  Color _typeBadgeColor(SpaceType type) {
    switch (type) {
      case SpaceType.home:
        return const Color(0xFF4CAF50);
      case SpaceType.office:
        return const Color(0xFF2196F3);
      case SpaceType.room:
        return const Color(0xFFFF9800);
      case SpaceType.storage:
        return const Color(0xFF9C27B0);
      case SpaceType.other:
        return const Color(0xFF607D8B);
    }
  }

  String _typeLabel(SpaceType type) {
    switch (type) {
      case SpaceType.home:
        return 'Casă';
      case SpaceType.office:
        return 'Birou';
      case SpaceType.room:
        return 'Cameră';
      case SpaceType.storage:
        return 'Depozit';
      case SpaceType.other:
        return 'Altele';
    }
  }

  Widget _buildTypeBadge(SpaceType type) {
    final color = _typeBadgeColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _typeLabel(type),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Combobox ──
        _buildCombobox(),
        // ── Search dropdown ──
        if (_showSearch) _buildSearchDropdown(),
        // ── Tree browser ──
        if (_showTree) _buildTreeBrowser(),
      ],
    );
  }

  Widget _buildCombobox() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (_showSearch || _showTree)
              ? AppColors.primary
              : AppColors.divider,
          width: (_showSearch || _showTree) ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Icon(Icons.location_on_outlined, color: AppColors.textHint, size: 20),
          ),
          // Center content
          Expanded(
            child: _selected != null && !_showSearch
                ? GestureDetector(
                    onTap: () {
                      setState(() {
                        _showSearch = true;
                        _showTree = false;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_selected!.name} (${_typeLabel(_selected!.type)})',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: _clearSelection,
                            child: const Icon(Icons.close_rounded,
                                size: 18, color: AppColors.textHint),
                          ),
                        ],
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: _showSearch,
                            onChanged: _onSearchChanged,
                            onTap: () {
                              if (!_showSearch) {
                                setState(() {
                                  _showSearch = true;
                                  _showTree = false;
                                });
                              }
                            },
                            decoration: const InputDecoration(
                              hintText: 'Caută sau selectează spațiu...',
                              hintStyle: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        if (_searching)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          // Chevron button for tree
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(11)),
              onTap: () {
                setState(() {
                  _showTree = !_showTree;
                  _showSearch = false;
                  _searchResults = null;
                  _searchController.clear();
                });
                if (_showTree) _loadRoots();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
                  ),
                ),
                child: AnimatedRotation(
                  turns: _showTree ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.expand_more_rounded,
                      color: AppColors.textHint, size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchDropdown() {
    if (_searchResults == null && !_searching) {
      // Hint state
      if (_searchController.text.trim().length < 2) {
        return _dropdownContainer(
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Tastează cel puțin 2 caractere pentru a căuta...',
              style: TextStyle(color: AppColors.textHint, fontSize: 13),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    if (_searching) {
      return _dropdownContainer(
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          ),
        ),
      );
    }

    if (_searchResults != null && _searchResults!.isEmpty) {
      return _dropdownContainer(
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Niciun spațiu găsit.',
            style: TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
        ),
      );
    }

    return _dropdownContainer(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 250),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: _searchResults!.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final space = _searchResults![index];
            return _buildSearchResultItem(space);
          },
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(Space space) {
    final isSelected = _selected?.id == space.id;
    return InkWell(
      onTap: () => _selectSpace(space),
      child: Container(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Checkmark for selected
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    space.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  if (space.fullPath != null && space.fullPath!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      space.fullPath!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildTypeBadge(space.type),
            const SizedBox(width: 8),
            Text(
              '${space.assetsCount}',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.inventory_2_outlined, size: 14, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeBrowser() {
    if (_loadingRoots) {
      return _dropdownContainer(
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
            ),
          ),
        ),
      );
    }

    if (_rootNodes.isEmpty) {
      return _dropdownContainer(
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Nu ai spații create.',
            style: TextStyle(color: AppColors.textHint, fontSize: 13),
          ),
        ),
      );
    }

    return _dropdownContainer(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 300),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _rootNodes
                .map((node) => _buildTreeNode(node, 0))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTreeNode(_TreeNode node, int depth) {
    final isSelected = _selected?.id == node.space.id;
    final hasChildren = node.space.childrenCount > 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            final fullPath = _buildPathForNode(node, _rootNodes, '');
            _selectSpace(node.space, computedFullPath: fullPath.isNotEmpty ? fullPath : node.space.name);
          },
          child: Container(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : null,
            padding: EdgeInsets.only(
              left: 12.0 + depth * 24.0,
              right: 12,
              top: 10,
              bottom: 10,
            ),
            child: Row(
              children: [
                // Chevron / spacer
                SizedBox(
                  width: 24,
                  height: 24,
                  child: hasChildren
                      ? node.loadingChildren
                          ? const Padding(
                              padding: EdgeInsets.all(4),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : GestureDetector(
                              onTap: () => _toggleNode(node),
                              child: AnimatedRotation(
                                turns: node.expanded ? 0.25 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: AppColors.textHint,
                                ),
                              ),
                            )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 6),
                // Checkmark for selected
                if (isSelected)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 16),
                  ),
                // Name
                Expanded(
                  child: Text(
                    node.space.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildTypeBadge(node.space.type),
              ],
            ),
          ),
        ),
        // Children
        if (node.expanded && node.childrenLoaded)
          ...node.children.map((child) => _buildTreeNode(child, depth + 1)),
      ],
    );
  }

  Widget _dropdownContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _TreeNode {
  final Space space;
  bool expanded;
  bool childrenLoaded;
  bool loadingChildren;
  List<_TreeNode> children;

  _TreeNode({
    required this.space,
    this.expanded = false,
    this.childrenLoaded = false,
    this.loadingChildren = false,
    this.children = const [],
  });
}

/// A dialog that wraps [SpacePickerWidget] for use in forms.
class SpacePickerDialog extends StatefulWidget {
  final SelectedSpace? initialValue;

  const SpacePickerDialog({super.key, this.initialValue});

  @override
  State<SpacePickerDialog> createState() => _SpacePickerDialogState();
}

class _SpacePickerDialogState extends State<SpacePickerDialog> {
  SelectedSpace? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
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
                const Expanded(
                  child: Text(
                    'Selectează spațiul',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Picker
            Flexible(
              child: SpacePickerWidget(
                initialValue: widget.initialValue,
                onChanged: (space) {
                  setState(() => _selected = space);
                },
              ),
            ),
            // Spațiu selectat info + buton confirmare
            if (_selected != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        _selected!.fullPath ?? _selected!.name,
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
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Confirmă selecția',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
