import 'package:equatable/equatable.dart';

enum AssetStatus { active, inRepair, decommissioned, transferred }

enum AssetCategory { electronics, furniture, vehicles, equipment, other }

class Asset extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? serialNumber;
  final AssetCategory category;
  final AssetStatus status;
  final String location;
  final double value;
  final DateTime purchaseDate;
  final DateTime? lastUpdated;
  final String? assignedTo;
  final String? imageUrl;

  const Asset({
    required this.id,
    required this.name,
    this.description,
    this.serialNumber,
    required this.category,
    required this.status,
    required this.location,
    required this.value,
    required this.purchaseDate,
    this.lastUpdated,
    this.assignedTo,
    this.imageUrl,
  });

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
      case AssetCategory.equipment:
        return 'Echipamente';
      case AssetCategory.other:
        return 'Altele';
    }
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        serialNumber,
        category,
        status,
        location,
        value,
        purchaseDate,
        lastUpdated,
        assignedTo,
        imageUrl,
      ];
}

