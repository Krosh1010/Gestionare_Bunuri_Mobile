import '../../domain/entities/asset.dart';

class AssetModel extends Asset {
  const AssetModel({
    required super.id,
    required super.name,
    super.description,
    super.serialNumber,
    required super.category,
    required super.status,
    required super.location,
    required super.value,
    required super.purchaseDate,
    super.lastUpdated,
    super.assignedTo,
    super.imageUrl,
  });

  factory AssetModel.fromJson(Map<String, dynamic> json) {
    return AssetModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      serialNumber: json['serialNumber'] as String?,
      category: AssetCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => AssetCategory.other,
      ),
      status: AssetStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AssetStatus.active,
      ),
      location: json['location'] as String,
      value: (json['value'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      assignedTo: json['assignedTo'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'serialNumber': serialNumber,
      'category': category.name,
      'status': status.name,
      'location': location,
      'value': value,
      'purchaseDate': purchaseDate.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
      'assignedTo': assignedTo,
      'imageUrl': imageUrl,
    };
  }
}

