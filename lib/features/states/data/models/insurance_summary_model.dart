import '../../domain/entities/insurance_summary.dart';

class InsuranceSummaryModel extends InsuranceSummary {
  const InsuranceSummaryModel({
    required super.totalCount,
    required super.expiredCount,
    required super.expiringSoonCount,
    required super.validMoreThanMonthCount,
    required super.assetsWithoutInsuranceCount,
    required super.totalInsuredValue,
  });

  factory InsuranceSummaryModel.fromJson(Map<String, dynamic> json) {
    return InsuranceSummaryModel(
      totalCount: json['totalCount'] as int? ?? 0,
      expiredCount: json['expiredCount'] as int? ?? 0,
      expiringSoonCount: json['expiringSoonCount'] as int? ?? 0,
      validMoreThanMonthCount: json['validMoreThanMonthCount'] as int? ?? 0,
      assetsWithoutInsuranceCount: json['assetsWithoutInsuranceCount'] as int? ?? 0,
      totalInsuredValue: (json['totalInsuredValue'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

