import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite_api_client/appwrite_api_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClient extends Mock implements Client;

void main() {
  group(AppwriteApiClient, () {
    late Client client;
    late AppwriteApiClient apiClient;

    setUp(() {
      client = _MockClient();
      apiClient = AppwriteApiClient.withClient(client);
    });

    test('can be created from an endpoint and a project ID', () {
      // The SDK stores its cookie jar under the documents directory.
      TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => Directory.systemTemp.createTempSync().path,
          );

      expect(
        AppwriteApiClient(
          endpoint: 'http://localhost/v1',
          projectId: 'hawkbee',
        ),
        isA<AppwriteApiClient>(),
      );
    });

    group('ping', () {
      test('completes when the server answers', () async {
        when(() => client.ping()).thenAnswer((_) async => 'Pong!');

        await expectLater(apiClient.ping(), completes);
        verify(() => client.ping()).called(1);
      });

      test('throws $AppwritePingFailure when the server fails', () async {
        final exception = AppwriteException('Project not found', 404);
        when(() => client.ping()).thenThrow(exception);

        await expectLater(
          apiClient.ping,
          throwsA(
            isA<AppwritePingFailure>().having(
              (failure) => failure.error,
              'error',
              exception,
            ),
          ),
        );
      });
    });
  });

  group(AppwritePingFailure, () {
    test('describes the underlying error', () {
      expect(
        const AppwritePingFailure('boom').toString(),
        'AppwritePingFailure: boom',
      );
    });
  });
}
