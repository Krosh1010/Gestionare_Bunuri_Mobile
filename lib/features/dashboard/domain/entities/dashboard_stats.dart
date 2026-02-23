import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int totalCount;
  final int electronicsCount;
  final int furnitureCount;
  final int vehiclesCount;
  final int documentsCount;
  final int otherCount;

  // Insurance
  final int totalInsurance;
  final int activeInsurance;
  final int expiredInsurance;
  final int expiringSoonInsurance;

  // Warranty
  final int totalWarranty;
  final int activeWarranty;
  final int expiredWarranty;
  final int expiringSoonWarranty;

  const DashboardStats({
    required this.totalCount,
    required this.electronicsCount,
    required this.furnitureCount,
    required this.vehiclesCount,
    required this.documentsCount,
    required this.otherCount,
    required this.totalInsurance,
    required this.activeInsurance,
    required this.expiredInsurance,
    required this.expiringSoonInsurance,
    required this.totalWarranty,
    required this.activeWarranty,
    required this.expiredWarranty,
    required this.expiringSoonWarranty,
  });

  @override
  List<Object?> get props => [
        totalCount,
        electronicsCount,
        furnitureCount,
        vehiclesCount,
        documentsCount,
        otherCount,
        totalInsurance,
        activeInsurance,
        expiredInsurance,
        expiringSoonInsurance,
        totalWarranty,
        activeWarranty,
        expiredWarranty,
        expiringSoonWarranty,
      ];
}
