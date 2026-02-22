import 'package:get_it/get_it.dart';
import '../network/api_client.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  // TODO: Înregistrează repositories, use cases, blocs
}

