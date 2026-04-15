import '../../domain/entities/asset.dart';

class AssetModel extends Asset {
  const AssetModel({
    required super.id,
    required super.name,
    super.description,
    required super.category,
    super.status,
    required super.value,
    required super.purchaseDate,
    super.createdAt,
    super.spaceId,
    super.spaceName,
    super.isLoaned,
    super.loanId,
    super.loanedToName,
    super.loanCondition,
    super.loanNotes,
    super.loanedAt,
    super.loanReturnedAt,
    super.loanConditionOnReturn,
    super.warrantyStatus,
    super.warrantyStartDate,
    super.warrantyEndDate,
    super.warrantyProvider,
    super.warrantyDocumentFileName,
    super.warrantyDocumentId,
    super.insuranceStatus,
    super.insuranceStartDate,
    super.insuranceEndDate,
    super.insuranceCompany,
    super.insuranceValue,
    super.insuranceDocumentFileName,
    super.insuranceDocumentId,
    super.customTrackerName,
    super.customTrackerStatus,
    super.customTrackerEndDate,
    super.barcode,
  });


  static AssetCategory _mapCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'electronics':
        return AssetCategory.electronics;
      case 'furniture':
        return AssetCategory.furniture;
      case 'vehicles':
        return AssetCategory.vehicles;
      case 'documents':
        return AssetCategory.documents;
      default:
        return AssetCategory.other;
    }
  }

  /// Maps API warrantyStatus int to enum
  /// 0=notStarted, 1=active, 2=expiringSoon, 3=expired, null=unknown
  static WarrantyStatus _mapWarrantyStatus(dynamic status) {
    if (status == null) return WarrantyStatus.unknown;
    final val = status is int ? status : int.tryParse(status.toString());
    switch (val) {
      case 0:
        return WarrantyStatus.notStarted;
      case 1:
        return WarrantyStatus.active;
      case 2:
        return WarrantyStatus.expiringSoon;
      case 3:
        return WarrantyStatus.expired;
      default:
        return WarrantyStatus.unknown;
    }
  }


  /// 0=notStarted, 1=active, 2=expiringSoon, 3=expired, null=unknown
  static InsuranceStatus _mapInsuranceStatus(dynamic status) {
    if (status == null) return InsuranceStatus.unknown;
    final val = status is int ? status : int.tryParse(status.toString());
    switch (val) {
      case 0:
        return InsuranceStatus.notStarted;
      case 1:
        return InsuranceStatus.active;
      case 2:
        return InsuranceStatus.expiringSoon;
      case 3:
        return InsuranceStatus.expired;
      default:
        return InsuranceStatus.unknown;
    }
  }


  /// 0=notStarted, 1=active, 2=expiringSoon, 3=expired, null=unknown
  static CustomTrackerStatus _mapCustomTrackerStatus(dynamic status) {
    if (status == null) return CustomTrackerStatus.unknown;
    final val = status is int ? status : int.tryParse(status.toString());
    switch (val) {
      case 0:
        return CustomTrackerStatus.notStarted;
      case 1:
        return CustomTrackerStatus.active;
      case 2:
        return CustomTrackerStatus.expiringSoon;
      case 3:
        return CustomTrackerStatus.expired;
      default:
        return CustomTrackerStatus.unknown;
    }
  }


  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  /// Create an AssetModel from API JSON
  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      category: _mapCategory(json['category'] as String?),
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      purchaseDate: _parseDate(json['purchaseDate']) ?? DateTime.now(),
      createdAt: _parseDate(json['createdAt']),
      spaceId: json['spaceId'] as int?,
      spaceName: json['spaceName'] as String?,
      isLoaned: json['isLoaned'] as bool? ?? false,
      loanId: json['loanId'] as int?,
      loanedToName: json['loanedToName'] as String?,
      loanCondition: json['loanCondition'] as String?,
      loanNotes: json['loanNotes'] as String?,
      loanedAt: _parseDate(json['loanedAt']),
      loanReturnedAt: _parseDate(json['loanReturnedAt']),
      loanConditionOnReturn: json['loanConditionOnReturn'] as String?,
      warrantyStatus: _mapWarrantyStatus(json['warrantyStatus']),
      warrantyStartDate: _parseDate(json['warrantyStartDate']),
      warrantyEndDate: _parseDate(json['warrantyEndDate']),
      warrantyProvider: json['warrantyProvider'] as String?,
      warrantyDocumentFileName: json['warrantyDocumentFileName'] as String?,
      warrantyDocumentId: json['warrantyDocumentId'] as int?,
      insuranceStatus: _mapInsuranceStatus(json['insuranceStatus']),
      insuranceStartDate: _parseDate(json['insuranceStartDate']),
      insuranceEndDate: _parseDate(json['insuranceEndDate']),
      insuranceCompany: json['insuranceCompany'] as String?,
      insuranceValue: (json['insuranceValue'] as num?)?.toDouble(),
      insuranceDocumentFileName: json['insuranceDocumentFileName'] as String?,
      insuranceDocumentId: json['insuranceDocumentId'] as int?,
      customTrackerName: json['customTrackerName'] as String?,
      customTrackerStatus: _mapCustomTrackerStatus(json['customTrackerStatus']),
      customTrackerEndDate: _parseDate(json['customTrackerEndDate']),
      barcode: json['barcode'] as String?,
    );
  }

  /// Convert to JSON for sending to API
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': _categoryToString(category),
      'value': value,
      'purchaseDate': purchaseDate.toIso8601String(),
      'spaceId': spaceId,
      'warrantyStatus': _warrantyStatusToInt(warrantyStatus),
      'warrantyStartDate': warrantyStartDate?.toIso8601String(),
      'warrantyEndDate': warrantyEndDate?.toIso8601String(),
      'warrantyProvider': warrantyProvider,
      'insuranceStatus': _insuranceStatusToInt(insuranceStatus),
      'insuranceStartDate': insuranceStartDate?.toIso8601String(),
      'insuranceEndDate': insuranceEndDate?.toIso8601String(),
      'insuranceCompany': insuranceCompany,
      'insuranceValue': insuranceValue,
      'customTrackerName': customTrackerName,
      'customTrackerStatus': _customTrackerStatusToInt(customTrackerStatus),
      'customTrackerEndDate': customTrackerEndDate?.toIso8601String(),
      'barcode': barcode,
    };
  }

  static String _categoryToString(AssetCategory category) {
    switch (category) {
      case AssetCategory.electronics:
        return 'electronics';
      case AssetCategory.furniture:
        return 'furniture';
      case AssetCategory.vehicles:
        return 'vehicles';
      case AssetCategory.documents:
        return 'documents';
      case AssetCategory.other:
        return 'other';
    }
  }

  static int? _warrantyStatusToInt(WarrantyStatus status) {
    switch (status) {
      case WarrantyStatus.notStarted:
        return 0;
      case WarrantyStatus.active:
        return 1;
      case WarrantyStatus.expiringSoon:
        return 2;
      case WarrantyStatus.expired:
        return 3;
      case WarrantyStatus.unknown:
        return null;
    }
  }

  static int? _insuranceStatusToInt(InsuranceStatus status) {
    switch (status) {
      case InsuranceStatus.notStarted:
        return 0;
      case InsuranceStatus.active:
        return 1;
      case InsuranceStatus.expiringSoon:
        return 2;
      case InsuranceStatus.expired:
        return 3;
      case InsuranceStatus.unknown:
        return null;
    }
  }

  static int? _customTrackerStatusToInt(CustomTrackerStatus status) {
    switch (status) {
      case CustomTrackerStatus.notStarted:
        return 0;
      case CustomTrackerStatus.active:
        return 1;
      case CustomTrackerStatus.expiringSoon:
        return 2;
      case CustomTrackerStatus.expired:
        return 3;
      case CustomTrackerStatus.unknown:
        return null;
    }
  }
}
