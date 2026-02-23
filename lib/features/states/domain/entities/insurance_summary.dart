import 'package:equatable/equatable.dart';

class InsuranceSummary extends Equatable {
  final int totalCount;
  final int expiredCount;
  final int expiringSoonCount;
  final int validMoreThanMonthCount;
  final int assetsWithoutInsuranceCount;
  final double totalInsuredValue;

  const InsuranceSummary({
    required this.totalCount,
    required this.expiredCount,
    required this.expiringSoonCount,
    required this.validMoreThanMonthCount,
    required this.assetsWithoutInsuranceCount,
    required this.totalInsuredValue,
  });

  @override
  List<Object?> get props => [
        totalCount,
        expiredCount,
        expiringSoonCount,
        validMoreThanMonthCount,
        assetsWithoutInsuranceCount,
        totalInsuredValue,
      ];
}

