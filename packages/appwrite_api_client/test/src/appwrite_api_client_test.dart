import 'dart:async';
import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:appwrite_api_client/appwrite_api_client.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
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

    test('keeps the session of the account asked for', () async {
      final user = _MockUser();
      when(() => user.email).thenReturn('blue@x.local');
      when(() => account.get()).thenAnswer((_) async => user);

      await apiClient.signIn(email: 'blue@x.local', password: 'secret');

      verifyNever(
        () => account.deleteSession(sessionId: any(named: 'sessionId')),
      );
      verifyNever(
        () => account.createEmailPasswordSession(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    test("closes another account's session before signing in", () async {
      final user = _MockUser();
      when(() => user.email).thenReturn('someone@else.local');
      when(() => account.get()).thenAnswer((_) async => user);
      when(() => account.deleteSession(sessionId: any(named: 'sessionId')))
          .thenAnswer((_) async {});
      when(
        () => account.createEmailPasswordSession(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _MockSession());

      await apiClient.signIn(email: 'blue@x.local', password: 'secret');

      verify(() => account.deleteSession(sessionId: 'current')).called(1);
      verify(
        () => account.createEmailPasswordSession(
          email: 'blue@x.local',
          password: 'secret',
        ),
      ).called(1);
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

  group('logging', () {
    late Account account;
    late AppwriteApiClient apiClient;
    late List<LogRecord> records;
    late StreamSubscription<LogRecord> subscription;
    late Level previousLevel;

    setUp(() {
      account = _MockAccount();
      apiClient = AppwriteApiClient.withClient(_MockClient(), account: account);
      records = [];
      previousLevel = Logger.root.level;
      Logger.root.level = Level.ALL;
      subscription = Logger.root.onRecord.listen(records.add);
    });

    tearDown(() async {
      await subscription.cancel();
      Logger.root.level = previousLevel;
    });

    List<String> lines() => [
      for (final record in records) '${record.level.name} ${record.message}',
    ];

    test(
      'M7.3 a sign-in logs its start and its end, not the password',
      () async {
        when(() => account.get()).thenThrow(AppwriteException('guests', 401));
        when(
          () => account.createEmailPasswordSession(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => _MockSession());

        await apiClient.signIn(email: 'blue@x.local', password: 'secret');

        expect(
          lines(),
          equals(['INFO sign-in: started', 'INFO sign-in: done']),
        );
        expect(
          records.map((record) => record.loggerName).toSet(),
          equals({'appwrite_api_client.AppwriteApiClient'}),
        );
      },
    );

    test('M7.3 a session already open is logged', () async {
      final user = _MockUser();
      when(() => user.email).thenReturn('blue@x.local');
      when(() => account.get()).thenAnswer((_) async => user);

      await apiClient.signIn(email: 'blue@x.local', password: 'secret');

      expect(
        lines(),
        equals([
          'INFO sign-in: started',
          'INFO sign-in: the session is already open',
          'INFO sign-in: done',
        ]),
      );
    });

    test('M7.3 a failed sign-in is SEVERE with its error and stack', () async {
      final exception = AppwriteException('down', 503);
      when(() => account.get()).thenThrow(exception);

      await expectLater(
        apiClient.signIn(email: 'blue@x.local', password: 'secret'),
        throwsA(isA<AppwriteSignInFailure>()),
      );

      final failed = records.singleWhere(
        (record) => record.level == Level.SEVERE,
      );
      expect(failed.message, equals('sign-in: failed'));
      expect(failed.error, equals(exception));
      expect(failed.stackTrace, isNotNull);
      expect(
        records.where((record) => record.message.contains('secret')),
        isEmpty,
      );
    });

    test('M7.3 a JWT is logged by its creation, never by its value', () async {
      when(() => account.createJWT())
          .thenAnswer((_) async => models.Jwt(jwt: 'jwt-value'));

      await apiClient.createJwt();

      expect(
        lines(),
        equals(['INFO create JWT: started', 'INFO create JWT: done']),
      );
      expect(
        records.where((record) => record.message.contains('jwt-value')),
        isEmpty,
      );
    });

    test('M7.3 a JWT that cannot be created is SEVERE', () async {
      when(() => account.createJWT())
          .thenThrow(AppwriteException('guests', 401));

      await expectLater(
        apiClient.createJwt,
        throwsA(isA<AppwriteSignInFailure>()),
      );

      expect(lines(), contains('SEVERE create JWT: failed'));
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
