import '../../../../core/network/api_client.dart';
import '../models/space_model.dart';

abstract class SpacesRemoteDataSource {
  Future<List<SpaceModel>> getParentSpaces();
  Future<List<SpaceModel>> getChildrenSpaces(int parentId);
  Future<List<SpaceModel>> getSpacePath(int spaceId);
  Future<List<SpaceModel>> searchSpaces(String query);
  Future<SpaceModel> createSpace(Map<String, dynamic> data);
  Future<SpaceModel> updateSpace(int id, Map<String, dynamic> data);
  Future<void> deleteSpace(int id);
}

class SpacesRemoteDataSourceImpl implements SpacesRemoteDataSource {
  final ApiClient apiClient;

  SpacesRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<SpaceModel>> getParentSpaces() async {
    final response = await apiClient.dio.get('/Spaces/parents');
    final list = response.data as List;
    return list
        .map((json) => SpaceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<SpaceModel>> getChildrenSpaces(int parentId) async {
    final response = await apiClient.dio.get('/Spaces/children/$parentId');
    final list = response.data as List;
    return list
        .map((json) => SpaceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<SpaceModel>> getSpacePath(int spaceId) async {
    final response = await apiClient.dio.get('/Spaces/path/$spaceId');
    final list = response.data as List;
    return list
        .map((json) => SpaceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<SpaceModel>> searchSpaces(String query) async {
    final response = await apiClient.dio.get('/Spaces/search',
        queryParameters: {'query': query});
    final list = response.data as List;
    return list
        .map((json) => SpaceModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SpaceModel> createSpace(Map<String, dynamic> data) async {
    final response = await apiClient.dio.post('/Spaces/create', data: data);
    return SpaceModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<SpaceModel> updateSpace(int id, Map<String, dynamic> data) async {
    final response = await apiClient.dio.patch('/Spaces/$id', data: data);
    return SpaceModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteSpace(int id) async {
    await apiClient.dio.delete('/Spaces/$id');
  }
}
