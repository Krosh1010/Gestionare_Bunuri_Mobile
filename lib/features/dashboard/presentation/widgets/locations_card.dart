import 'package:flutter/material.dart';

class LocationNode {
  final String id;
  final String name;
  final String type;
  List<LocationNode> children;
  bool expanded;
  bool childrenLoaded;
  bool loadingChildren;

  LocationNode({
    required this.id,
    required this.name,
    required this.type,
    this.children = const [],
    this.expanded = false,
    this.childrenLoaded = false,
    this.loadingChildren = false,
  });
}

class LocationsCard extends StatefulWidget {
  final List<LocationNode> locationTree;
  final int totalLocations;
  final bool isLoading;
  final VoidCallback? onViewAll;
  final Future<void> Function(LocationNode node)? onLoadChildren;

  const LocationsCard({
    super.key,
    required this.locationTree,
    required this.totalLocations,
    this.isLoading = false,
    this.onViewAll,
    this.onLoadChildren,
  });

  @override
  State<LocationsCard> createState() => _LocationsCardState();
}

class _LocationsCardState extends State<LocationsCard> {
  void _toggleExpand(LocationNode node) async {
    if (!node.childrenLoaded && !node.loadingChildren) {
      // Lazy-load children from API
      if (widget.onLoadChildren != null) {
        setState(() {
          node.loadingChildren = true;
        });
        await widget.onLoadChildren!(node);
        setState(() {
          node.loadingChildren = false;
          node.childrenLoaded = true;
          node.expanded = true;
        });
        return;
      }
    }
    setState(() {
      node.expanded = !node.expanded;
    });
  }

  String _getTypeEmoji(String type) {
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

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return 'CASĂ';
      case 'office':
        return 'BIROU';
      case 'room':
        return 'CAMERĂ';
      case 'storage':
        return 'DEPOZIT';
      default:
        return type.toUpperCase();
    }
  }

  Color _getTypeBgColor(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return const Color(0xFF10B981).withValues(alpha: 0.1);
      case 'office':
        return const Color(0xFF667EEA).withValues(alpha: 0.1);
      case 'room':
        return const Color(0xFFF59E0B).withValues(alpha: 0.1);
      case 'storage':
        return const Color(0xFFEF4444).withValues(alpha: 0.1);
      default:
        return const Color(0xFF6B7280).withValues(alpha: 0.1);
    }
  }

  Color _getTypeTextColor(String type) {
    switch (type.toLowerCase()) {
      case 'home':
        return const Color(0xFF059669);
      case 'office':
        return const Color(0xFF667EEA);
      case 'room':
        return const Color(0xFFD97706);
      case 'storage':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Distribuție Locații',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              if (widget.onViewAll != null)
                GestureDetector(
                  onTap: widget.onViewAll,
                  child: const Text(
                    'Vezi toate →',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF667EEA),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Tree Container
          Container(
            constraints: const BoxConstraints(maxHeight: 350),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: widget.isLoading
                ? _buildLoading()
                : widget.locationTree.isEmpty
                    ? _buildEmpty()
                    : SingleChildScrollView(
                        child: Column(
                          children: widget.locationTree
                              .map((node) => _buildTreeNode(node, 0))
                              .toList(),
                        ),
                      ),
          ),
          const SizedBox(height: 16),
          // Location Stats
          Row(
            children: [
              Expanded(
                child: _LocationStat(
                  emoji: '📍',
                  value: '${widget.totalLocations}',
                  label: 'Locații încărcate',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LocationStat(
                  emoji: '🏠',
                  value: '${widget.locationTree.length}',
                  label: 'Locații principale',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF667EEA),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Se încarcă locațiile...',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('📍', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          const Text(
            'Nu există locații definite.',
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Adaugă locație',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeNode(LocationNode node, int level) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Node Header
        GestureDetector(
          onTap: () => _toggleExpand(node),
          child: Container(
            margin: EdgeInsets.only(left: level * 16.0, bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                // Expand icon
                AnimatedRotation(
                  turns: node.expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: node.loadingChildren
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF667EEA),
                          ),
                        )
                      : const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Color(0xFF9CA3AF),
                        ),
                ),
                const SizedBox(width: 6),
                // Emoji
                Text(
                  _getTypeEmoji(node.type),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                // Name
                Expanded(
                  child: Text(
                    node.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getTypeBgColor(node.type),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getTypeLabel(node.type),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getTypeTextColor(node.type),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                // Children count
                if (node.childrenLoaded && node.children.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    '${node.children.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Children
        if (node.expanded && node.children.isNotEmpty)
          Container(
            margin: EdgeInsets.only(left: (level + 1) * 8.0),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 2,
                ),
              ),
            ),
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              children: node.children
                  .map((child) => _buildTreeNode(child, level + 1))
                  .toList(),
            ),
          ),
        // Empty children
        if (node.expanded &&
            node.childrenLoaded &&
            node.children.isEmpty)
          Padding(
            padding: EdgeInsets.only(left: (level + 1) * 20.0 + 12, bottom: 4),
            child: const Text(
              '— Fără sub-locații',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

class _LocationStat extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _LocationStat({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
