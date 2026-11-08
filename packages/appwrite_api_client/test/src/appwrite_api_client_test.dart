import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite_api_client/appwrite_api_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClient extends Mock implements Client;

class _MockAccount extends Mock implements Account;

class _MockUser extends Mock implements models.User;

class _MockSession extends Mock implements models.Session;

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

  group('sign-in', () {
    late Account account;
    late AppwriteApiClient apiClient;

    setUp(() {
      account = _MockAccount();
      apiClient = AppwriteApiClient.withClient(_MockClient(), account: account);
    });

    test('opens a session when there is none', () async {
      when(() => account.get()).thenThrow(AppwriteException('guests', 401));
      when(
        () => account.createEmailPasswordSession(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _MockSession());

      await apiClient.signIn(email: 'blue@x.local', password: 'secret');

      verify(
        () => account.createEmailPasswordSession(
          email: 'blue@x.local',
          password: 'secret',
        ),
      ).called(1);
    });

    test('keeps the session that is open', () async {
      when(() => account.get()).thenAnswer((_) async => _MockUser());

      await apiClient.signIn(email: 'blue@x.local', password: 'secret');

      verifyNever(
        () => account.createEmailPasswordSession(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    test('throws $AppwriteSignInFailure when Appwrite fails', () async {
      final exception = AppwriteException('down', 503);
      when(() => account.get()).thenThrow(exception);

      await expectLater(
        apiClient.signIn(email: 'blue@x.local', password: 'secret'),
        throwsA(
          isA<AppwriteSignInFailure>().having(
            (failure) => failure.error,
            'error',
            exception,
          ),
        ),
      );
    });

    test('gives a JWT of the signed-in account', () async {
      when(() => account.createJWT())
          .thenAnswer((_) async => models.Jwt(jwt: 'jwt-1'));

      expect(await apiClient.createJwt(), 'jwt-1');
    });

    test('throws $AppwriteSignInFailure for a JWT without a session', () {
      when(() => account.createJWT())
          .thenThrow(AppwriteException('guests', 401));

      expect(apiClient.createJwt, throwsA(isA<AppwriteSignInFailure>()));
    });
  });

  group(AppwriteSignInFailure, () {
    test('describes the underlying error', () {
      expect(
        const AppwriteSignInFailure('boom').toString(),
        'AppwriteSignInFailure: boom',
      );
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
