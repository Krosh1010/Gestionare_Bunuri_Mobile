import 'package:equatable/equatable.dart';

enum AssetStatus { active, inRepair, decommissioned, transferred }

enum AssetCategory { electronics, furniture, vehicles, documents, other }

// warrantyStatus from API: 0=notStarted, 1=active, 2=expiringSoon, 3=expired, null=unknown
enum WarrantyStatus { notStarted, active, expiringSoon, expired, unknown }

// insuranceStatus from API: 0=notStarted, 1=active, 2=expiringSoon, 3=expired, null=unknown
enum InsuranceStatus { notStarted, active, expiringSoon, expired, unknown }

// customTrackerStatus from API: 0=notStarted, 1=active, 2=expiringSoon, 3=expired, null=unknown
enum CustomTrackerStatus { notStarted, active, expiringSoon, expired, unknown }

class Asset extends Equatable {
  final String id;
  final String name;
  final String? description;
  final AssetCategory category;
  final AssetStatus status;
  final double value;
  final DateTime purchaseDate;
  final DateTime? createdAt;
  final int? spaceId;
  final String? spaceName;
  final bool isLoaned;

  // Loan
  final int? loanId;
  final String? loanedToName;
  final String? loanCondition;
  final String? loanNotes;
  final DateTime? loanedAt;
  final DateTime? loanReturnedAt;
  final String? loanConditionOnReturn;

  // Warranty
  final WarrantyStatus warrantyStatus;
  final DateTime? warrantyStartDate;
  final DateTime? warrantyEndDate;
  final String? warrantyProvider;
  final String? warrantyDocumentFileName;
  final int? warrantyDocumentId;

  // Insurance
  final InsuranceStatus insuranceStatus;
  final DateTime? insuranceStartDate;
  final DateTime? insuranceEndDate;
  final String? insuranceCompany;
  final double? insuranceValue;
  final String? insuranceDocumentFileName;
  final int? insuranceDocumentId;

  // Custom Tracker
  final String? customTrackerName;
  final CustomTrackerStatus customTrackerStatus;
  final DateTime? customTrackerEndDate;

  // Barcode
  final String? barcode;

  const Asset({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    this.status = AssetStatus.active,
    required this.value,
    required this.purchaseDate,
    this.createdAt,
    this.spaceId,
    this.spaceName,
    this.isLoaned = false,
    this.loanId,
    this.loanedToName,
    this.loanCondition,
    this.loanNotes,
    this.loanedAt,
    this.loanReturnedAt,
    this.loanConditionOnReturn,
    this.warrantyStatus = WarrantyStatus.unknown,
    this.warrantyStartDate,
    this.warrantyEndDate,
    this.warrantyProvider,
    this.warrantyDocumentFileName,
    this.warrantyDocumentId,
    this.insuranceStatus = InsuranceStatus.unknown,
    this.insuranceStartDate,
    this.insuranceEndDate,
    this.insuranceCompany,
    this.insuranceValue,
    this.insuranceDocumentFileName,
    this.insuranceDocumentId,
    this.customTrackerName,
    this.customTrackerStatus = CustomTrackerStatus.unknown,
    this.customTrackerEndDate,
    this.barcode,
  });

  // Convenience getters
  String get location => spaceName ?? 'Neatribuit';

  int? get warrantyDaysLeft {
    if (warrantyEndDate == null) return null;
    final days = warrantyEndDate!.difference(DateTime.now()).inDays;
    return days > 0 ? days : 0;
  }

  int? get insuranceDaysLeft {
    if (insuranceEndDate == null) return null;
    final days = insuranceEndDate!.difference(DateTime.now()).inDays;
    return days > 0 ? days : 0;
  }

  int? get customTrackerDaysLeft {
    if (customTrackerEndDate == null) return null;
    final days = customTrackerEndDate!.difference(DateTime.now()).inDays;
    return days > 0 ? days : 0;
  }

  String get statusLabel {
    switch (status) {
      case AssetStatus.active:
        return 'Activ';
      case AssetStatus.inRepair:
        return 'În Reparație';
      case AssetStatus.decommissioned:
        return 'Casat';
      case AssetStatus.transferred:
        return 'Transferat';
    }
  }

  String get categoryLabel {
    switch (category) {
      case AssetCategory.electronics:
        return 'Electronică';
      case AssetCategory.furniture:
        return 'Mobilier';
      case AssetCategory.vehicles:
        return 'Vehicule';
      case AssetCategory.documents:
        return 'Documente';
      case AssetCategory.other:
        return 'Altele';
    }
  }

  String get warrantyStatusLabel {
    switch (warrantyStatus) {
      case WarrantyStatus.notStarted:
        return 'Neîncepută';
      case WarrantyStatus.active:
        return 'Activă';
      case WarrantyStatus.expiringSoon:
        return 'Expiră curând';
      case WarrantyStatus.expired:
        return 'Expirată';
      case WarrantyStatus.unknown:
        return 'Lipsă';
    }
  }

  String get insuranceStatusLabel {
    switch (insuranceStatus) {
      case InsuranceStatus.notStarted:
        return 'Neîncepută';
      case InsuranceStatus.active:
        return 'Activă';
      case InsuranceStatus.expiringSoon:
        return 'Expiră curând';
      case InsuranceStatus.expired:
        return 'Expirată';
      case InsuranceStatus.unknown:
        return 'Lipsă';
    }
  }

  String get customTrackerStatusLabel {
    switch (customTrackerStatus) {
      case CustomTrackerStatus.notStarted:
        return 'Neînceput';
      case CustomTrackerStatus.active:
        return 'Activ';
      case CustomTrackerStatus.expiringSoon:
        return 'Expiră degrabă';
      case CustomTrackerStatus.expired:
        return 'Expirat';
      case CustomTrackerStatus.unknown:
        return 'Tracker lipsă';
    }
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        status,
        value,
        purchaseDate,
        createdAt,
        spaceId,
        spaceName,
        isLoaned,
        loanId,
        loanedToName,
        loanCondition,
        loanNotes,
        loanedAt,
        loanReturnedAt,
        loanConditionOnReturn,
        warrantyStatus,
        warrantyStartDate,
        warrantyEndDate,
        warrantyProvider,
        warrantyDocumentFileName,
        warrantyDocumentId,
        insuranceStatus,
        insuranceStartDate,
        insuranceEndDate,
        insuranceCompany,
        insuranceValue,
        insuranceDocumentFileName,
        insuranceDocumentId,
        customTrackerName,
        customTrackerStatus,
        customTrackerEndDate,
        barcode,
      ];
}
