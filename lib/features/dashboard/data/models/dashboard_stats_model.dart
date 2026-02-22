import '../../domain/entities/dashboard_stats.dart';

class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required super.totalAssets,
    required super.activeAssets,
    required super.inRepairAssets,
    required super.decommissionedAssets,
    required super.totalValue,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalAssets: json['totalAssets'] as int,
      activeAssets: json['activeAssets'] as int,
      inRepairAssets: json['inRepairAssets'] as int,
      decommissionedAssets: json['decommissionedAssets'] as int,
      totalValue: (json['totalValue'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAssets': totalAssets,
      'activeAssets': activeAssets,
      'inRepairAssets': inRepairAssets,
      'decommissionedAssets': decommissionedAssets,
      'totalValue': totalValue,
    };
  }
}

