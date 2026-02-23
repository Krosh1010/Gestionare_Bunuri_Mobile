import '../../domain/entities/space.dart';

class SpaceModel extends Space {
  const SpaceModel({
    required super.id,
    required super.name,
    required super.type,
    super.parentSpaceId,
    super.childrenCount,
    super.assetsCount,
  });

  static SpaceType _mapType(dynamic type) {
    if (type is int) {
      switch (type) {
        case 0:
          return SpaceType.home;
        case 1:
          return SpaceType.office;
        case 2:
          return SpaceType.room;
        case 3:
          return SpaceType.storage;
        default:
          return SpaceType.other;
      }
    }
    final str = type?.toString().toLowerCase() ?? '';
    switch (str) {
      case 'home':
        return SpaceType.home;
      case 'office':
        return SpaceType.office;
      case 'room':
        return SpaceType.room;
      case 'storage':
        return SpaceType.storage;
      default:
        return SpaceType.other;
    }
  }

  static int typeToInt(SpaceType type) {
    switch (type) {
      case SpaceType.home:
        return 0;
      case SpaceType.office:
        return 1;
      case SpaceType.room:
        return 2;
      case SpaceType.storage:
        return 3;
      case SpaceType.other:
        return 4;
    }
  }

  factory SpaceModel.fromJson(Map<String, dynamic> json) {
    return SpaceModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      type: _mapType(json['type']),
      parentSpaceId: json['parentSpaceId'] as int?,
      childrenCount: json['childrenCount'] as int? ?? 0,
      assetsCount: json['assetsCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': typeToInt(type),
      'parentSpaceId': parentSpaceId,
    };
  }
}

