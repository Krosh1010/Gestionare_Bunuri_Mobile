import '../../domain/entities/warranty_summary.dart';

class WarrantySummaryModel extends WarrantySummary {
  const WarrantySummaryModel({
    required super.totalCount,
    required super.expiredCount,
    required super.expiringSoonCount,
    required super.validMoreThanMonthCount,
    required super.assetsWithoutWarrantyCount,
  });

  factory WarrantySummaryModel.fromJson(Map<String, dynamic> json) {
    return WarrantySummaryModel(
      totalCount: json['totalCount'] as int? ?? 0,
      expiredCount: json['expiredCount'] as int? ?? 0,
      expiringSoonCount: json['expiringSoonCount'] as int? ?? 0,
      validMoreThanMonthCount: json['validMoreThanMonthCount'] as int? ?? 0,
      assetsWithoutWarrantyCount: json['assetsWithoutWarrantyCount'] as int? ?? 0,
    );
  }
}
