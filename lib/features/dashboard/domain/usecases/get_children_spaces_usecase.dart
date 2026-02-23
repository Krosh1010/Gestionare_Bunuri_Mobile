import '../entities/space.dart';
import '../repositories/dashboard_repository.dart';

class GetChildrenSpacesUseCase {
  final DashboardRepository repository;

  GetChildrenSpacesUseCase({required this.repository});

  Future<List<Space>> call(String parentId) async {
    return await repository.getChildrenSpaces(parentId);
  }
}

