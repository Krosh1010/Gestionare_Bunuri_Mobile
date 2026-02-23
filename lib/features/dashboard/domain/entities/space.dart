import 'package:equatable/equatable.dart';

class Space extends Equatable {
  final String id;
  final String name;
  final String type;
  final String? parentId;
  final int childrenCount;
  final int assetsCount;

  const Space({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    this.childrenCount = 0,
    this.assetsCount = 0,
  });

  @override
  List<Object?> get props => [id, name, type, parentId, childrenCount, assetsCount];
}
