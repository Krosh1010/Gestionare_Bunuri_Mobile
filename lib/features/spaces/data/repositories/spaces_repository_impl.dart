import '../../domain/entities/space.dart';
import '../../domain/repositories/spaces_repository.dart';
import '../datasources/spaces_remote_datasource.dart';

class SpacesRepositoryImpl implements SpacesRepository {
  final SpacesRemoteDataSource remoteDataSource;

  SpacesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<Space>> getParentSpaces() async {
    return await remoteDataSource.getParentSpaces();
  }

  @override
  Future<List<Space>> getChildrenSpaces(int parentId) async {
    return await remoteDataSource.getChildrenSpaces(parentId);
  }

  @override
  Future<List<Space>> getSpacePath(int spaceId) async {
    return await remoteDataSource.getSpacePath(spaceId);
  }

  @override
  Future<Space> createSpace(Map<String, dynamic> data) async {
    return await remoteDataSource.createSpace(data);
  }

  @override
  Future<Space> updateSpace(int id, Map<String, dynamic> data) async {
    return await remoteDataSource.updateSpace(id, data);
  }

  @override
  Future<void> deleteSpace(int id) async {
    await remoteDataSource.deleteSpace(id);
  }
}
