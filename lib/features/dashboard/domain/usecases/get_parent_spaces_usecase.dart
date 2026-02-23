import '../entities/space.dart';
import '../repositories/dashboard_repository.dart';

class GetParentSpacesUseCase {
  final DashboardRepository repository;

  GetParentSpacesUseCase({required this.repository});

  Future<List<Space>> call() async {
    return await repository.getParentSpaces();
  }
}

