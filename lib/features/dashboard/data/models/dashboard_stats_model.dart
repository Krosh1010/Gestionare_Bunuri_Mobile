import '../../domain/entities/dashboard_stats.dart';

class DashboardStatsModel extends DashboardStats {
  const DashboardStatsModel({
    required super.totalCount,
    required super.electronicsCount,
    required super.furnitureCount,
    required super.vehiclesCount,
    required super.documentsCount,
    required super.otherCount,
    required super.totalInsurance,
    required super.activeInsurance,
    required super.expiredInsurance,
    required super.expiringSoonInsurance,
    required super.totalWarranty,
    required super.activeWarranty,
    required super.expiredWarranty,
    required super.expiringSoonWarranty,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      totalCount: json['totalCount'] as int? ?? 0,
      electronicsCount: json['electronicsCount'] as int? ?? 0,
      furnitureCount: json['furnitureCount'] as int? ?? 0,
      vehiclesCount: json['vehiclesCount'] as int? ?? 0,
      documentsCount: json['documentsCount'] as int? ?? 0,
      otherCount: json['otherCount'] as int? ?? 0,
      totalInsurance: json['totalInsurance'] as int? ?? 0,
      activeInsurance: json['activeInsurance'] as int? ?? 0,
      expiredInsurance: json['expiredInsurance'] as int? ?? 0,
      expiringSoonInsurance: json['expiringSoonInsurance'] as int? ?? 0,
      totalWarranty: json['totalWarranty'] as int? ?? 0,
      activeWarranty: json['activeWarranty'] as int? ?? 0,
      expiredWarranty: json['expiredWarranty'] as int? ?? 0,
      expiringSoonWarranty: json['expiringSoonWarranty'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCount': totalCount,
      'electronicsCount': electronicsCount,
      'furnitureCount': furnitureCount,
      'vehiclesCount': vehiclesCount,
      'documentsCount': documentsCount,
      'otherCount': otherCount,
      'totalInsurance': totalInsurance,
      'activeInsurance': activeInsurance,
      'expiredInsurance': expiredInsurance,
      'expiringSoonInsurance': expiringSoonInsurance,
      'totalWarranty': totalWarranty,
      'activeWarranty': activeWarranty,
      'expiredWarranty': expiredWarranty,
      'expiringSoonWarranty': expiringSoonWarranty,
    };
  }
}
