import 'package:equatable/equatable.dart';

class CoverageAsset extends Equatable {
  final String assetName;
  final String category;
  final String company;
  final int daysLeft;
  final DateTime? endDate;
  final DateTime? startDate;
  final double value;
  final String provider;

  const CoverageAsset({
    required this.assetName,
    required this.category,
    required this.company,
    required this.daysLeft,
    this.endDate,
    this.startDate,
    required this.value,
    required this.provider,
  });

  @override
  List<Object?> get props => [
        assetName,
        category,
        company,
        daysLeft,
        endDate,
        startDate,
        value,
        provider,
      ];
}
