import 'package:equatable/equatable.dart';

class WarrantySummary extends Equatable {
  final int totalCount;
  final int expiredCount;
  final int expiringSoonCount;
  final int validMoreThanMonthCount;
  final int assetsWithoutWarrantyCount;

  const WarrantySummary({
    required this.totalCount,
    required this.expiredCount,
    required this.expiringSoonCount,
    required this.validMoreThanMonthCount,
    required this.assetsWithoutWarrantyCount,
  });

  @override
  List<Object?> get props => [
        totalCount,
        expiredCount,
        expiringSoonCount,
        validMoreThanMonthCount,
    assetsWithoutWarrantyCount,
      ];
}
