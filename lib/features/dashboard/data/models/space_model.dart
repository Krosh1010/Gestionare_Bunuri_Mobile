import '../../domain/entities/space.dart';

class SpaceModel extends Space {
  const SpaceModel({
    required super.id,
    required super.name,
    required super.type,
    super.parentId,
    super.childrenCount,
    super.assetsCount,
  });

  /// Maps int type from API to string label
  static String _mapType(dynamic type) {
    if (type is int) {
      switch (type) {
        case 0:
          return 'home';
        case 1:
          return 'office';
        case 2:
          return 'room';
        case 3:
          return 'storage';
        default:
          return 'other';
      }
    }
    return type?.toString() ?? 'other';
  }

  factory SpaceModel.fromJson(Map<String, dynamic> json) {
    return SpaceModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      type: _mapType(json['type']),
      parentId: json['parentSpaceId']?.toString(),
      childrenCount: json['childrenCount'] as int? ?? 0,
      assetsCount: json['assetsCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'parentId': parentId,
    };
  }
}
