import 'package:equatable/equatable.dart';

enum SpaceType { home, office, room, storage, other }

class Space extends Equatable {
  final int id;
  final String name;
  final SpaceType type;
  final int? parentSpaceId;
  final int childrenCount;
  final int assetsCount;

  const Space({
    required this.id,
    required this.name,
    required this.type,
    this.parentSpaceId,
    this.childrenCount = 0,
    this.assetsCount = 0,
  });

  String get typeLabel {
    switch (type) {
      case SpaceType.home:
        return 'Casă';
      case SpaceType.office:
        return 'Birou';
      case SpaceType.room:
        return 'Cameră';
      case SpaceType.storage:
        return 'Depozit';
      case SpaceType.other:
        return 'Altele';
    }
  }

  String get typeEmoji {
    switch (type) {
      case SpaceType.home:
        return '🏠';
      case SpaceType.office:
        return '🏢';
      case SpaceType.room:
        return '🚪';
      case SpaceType.storage:
        return '📦';
      case SpaceType.other:
        return '📍';
    }
  }

  @override
  List<Object?> get props => [id, name, type, parentSpaceId, childrenCount, assetsCount];
}

