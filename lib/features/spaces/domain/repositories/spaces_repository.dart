import '../entities/space.dart';

abstract class SpacesRepository {
  Future<List<Space>> getParentSpaces();
  Future<List<Space>> getChildrenSpaces(int parentId);
  Future<List<Space>> getSpacePath(int spaceId);
  Future<Space> createSpace(Map<String, dynamic> data);
  Future<Space> updateSpace(int id, Map<String, dynamic> data);
  Future<void> deleteSpace(int id);
}
