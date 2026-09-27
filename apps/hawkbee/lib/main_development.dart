import 'package:backend_status_repository/backend_status_repository.dart';
import 'package:hawkbee/app/app.dart';
import 'package:hawkbee/bootstrap.dart';

Future<void> main() async {
  await bootstrap(
    (apiClient) => App(
      backendStatusRepository: BackendStatusRepository(apiClient: apiClient),
    ),
  );
}
