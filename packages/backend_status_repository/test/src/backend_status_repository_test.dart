import 'package:appwrite_api_client/appwrite_api_client.dart';
import 'package:backend_status_repository/backend_status_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppwriteApiClient extends Mock implements AppwriteApiClient;

void main() {
  group(BackendStatusRepository, () {
    late AppwriteApiClient apiClient;
    late BackendStatusRepository repository;

    setUp(() {
      apiClient = _MockAppwriteApiClient();
      repository = BackendStatusRepository(apiClient: apiClient);
    });

    group('checkConnection', () {
      test('completes when the backend answers', () async {
        when(() => apiClient.ping()).thenAnswer((_) async {});

        await expectLater(repository.checkConnection(), completes);
        verify(() => apiClient.ping()).called(1);
      });

      test('throws $BackendUnreachableException when the ping fails', () async {
        when(() => apiClient.ping())
            .thenThrow(const AppwritePingFailure('Connection refused'));

        await expectLater(
          repository.checkConnection,
          throwsA(
            isA<BackendUnreachableException>().having(
              (exception) => exception.reason,
              'reason',
              'Connection refused',
            ),
          ),
        );
      });
    });
  });

  group(BackendUnreachableException, () {
    test('describes the reason', () {
      expect(
        const BackendUnreachableException('timeout').toString(),
        'BackendUnreachableException: timeout',
      );
    });
  });
}
