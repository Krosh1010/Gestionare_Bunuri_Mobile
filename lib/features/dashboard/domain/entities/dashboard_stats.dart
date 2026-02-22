import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int totalAssets;
  final int activeAssets;
  final int inRepairAssets;
  final int decommissionedAssets;
  final double totalValue;

  const DashboardStats({
    required this.totalAssets,
    required this.activeAssets,
    required this.inRepairAssets,
    required this.decommissionedAssets,
    required this.totalValue,
  });

  @override
  List<Object?> get props => [totalAssets, activeAssets, inRepairAssets, decommissionedAssets, totalValue];
}

