import 'package:flutter/material.dart';

class StatusStatsCard extends StatelessWidget {
  final String title;
  final int total;
  final int expired;
  final int expiringSoon;
  final int active;
  final Color topBorderColor;

  const StatusStatsCard({
    super.key,
    required this.title,
    required this.total,
    required this.expired,
    required this.expiringSoon,
    required this.active,
    required this.topBorderColor,
  });

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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top colored border
          Container(
            height: 4,
            color: topBorderColor,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 12),
                // Total number
                Text(
                  '$total',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    height: 1,
                  ),
                ),
                const SizedBox(height: 16),
                // Breakdown items
                _BreakdownItem(
                  label: 'Expirate',
                  value: expired,
                  type: _BreakdownType.urgent,
                ),
                const SizedBox(height: 8),
                _BreakdownItem(
                  label: 'Aproape de expirare',
                  value: expiringSoon,
                  type: _BreakdownType.warning,
                ),
                const SizedBox(height: 8),
                _BreakdownItem(
                  label: 'Active',
                  value: active,
                  type: _BreakdownType.info,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _BreakdownType { urgent, warning, info }

class _BreakdownItem extends StatelessWidget {
  final String label;
  final int value;
  final _BreakdownType type;

  const _BreakdownItem({
    required this.label,
    required this.value,
    required this.type,
  });

  Color get _bgColor {
    switch (type) {
      case _BreakdownType.urgent:
        return const Color(0xFFEF4444).withValues(alpha: 0.1);
      case _BreakdownType.warning:
        return const Color(0xFFF59E0B).withValues(alpha: 0.1);
      case _BreakdownType.info:
        return const Color(0xFF3B82F6).withValues(alpha: 0.1);
    }
  }

  Color get _labelColor {
    switch (type) {
      case _BreakdownType.urgent:
        return const Color(0xFFDC2626);
      case _BreakdownType.warning:
        return const Color(0xFFD97706);
      case _BreakdownType.info:
        return const Color(0xFF2563EB);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _labelColor,
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
