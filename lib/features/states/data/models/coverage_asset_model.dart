import '../../domain/entities/coverage_asset.dart';

class CoverageAssetModel extends CoverageAsset {
  const CoverageAssetModel({
    required super.assetName,
    required super.category,
    required super.company,
    required super.daysLeft,
    super.endDate,
    super.startDate,
    required super.value,
    required super.provider,
  });

  factory CoverageAssetModel.fromJson(Map<String, dynamic> json) {
    return CoverageAssetModel(
      assetName: json['assetName'] as String? ?? '',
      category: json['category'] as String? ?? '',
      company: json['company'] as String? ?? '',
      daysLeft: json['daysLeft'] as int? ?? 0,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      provider: json['provider'] as String? ?? '',
    );
  }
}
