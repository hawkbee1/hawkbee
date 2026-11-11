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

class _MockTablesDB extends Mock implements TablesDB;

class _MockFunctions extends Mock implements Functions;

class _MockExecution extends Mock implements models.Execution;

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

  group('accounts', () {
    late Account account;
    late AppwriteApiClient apiClient;

    setUp(() {
      account = _MockAccount();
      apiClient = AppwriteApiClient.withClient(_MockClient(), account: account);
    });

    void stubSession() => when(
      () => account.createEmailPasswordSession(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => _MockSession());

    void stubCreate() => when(
      () => account.create(
        userId: any(named: 'userId'),
        email: any(named: 'email'),
        password: any(named: 'password'),
        name: any(named: 'name'),
      ),
    ).thenAnswer((_) async => _MockUser());

    group('signUp', () {
      test('M7.12 creates the account, then signs it in', () async {
        when(() => account.deleteSession(sessionId: any(named: 'sessionId')))
            .thenThrow(AppwriteException('guests', 401));
        stubCreate();
        stubSession();

        await apiClient.signUp(
          email: 'new@x.local',
          password: 'secret-123',
          name: 'New',
        );

        verifyInOrder([
          () => account.create(
            userId: any(named: 'userId', that: isNotEmpty),
            email: 'new@x.local',
            password: 'secret-123',
            name: 'New',
          ),
          () => account.createEmailPasswordSession(
            email: 'new@x.local',
            password: 'secret-123',
          ),
        ]);
      });

      test('M7.12 closes a session still open first', () async {
        when(() => account.deleteSession(sessionId: any(named: 'sessionId')))
            .thenAnswer((_) async {});
        stubCreate();
        stubSession();

        await apiClient.signUp(
          email: 'new@x.local',
          password: 'secret-123',
          name: 'New',
        );

        verify(() => account.deleteSession(sessionId: 'current')).called(1);
      });

      test('M7.12 an email already used is a ${AppwriteFailureKind.conflict} '
          'failure', () async {
        when(() => account.deleteSession(sessionId: any(named: 'sessionId')))
            .thenThrow(AppwriteException('guests', 401));
        final exception = AppwriteException(
          'exists',
          409,
          'user_already_exists',
        );
        when(
          () => account.create(
            userId: any(named: 'userId'),
            email: any(named: 'email'),
            password: any(named: 'password'),
            name: any(named: 'name'),
          ),
        ).thenThrow(exception);

        await expectLater(
          apiClient.signUp(
            email: 'a@x.local',
            password: 'secret-123',
            name: 'A',
          ),
          throwsA(
            isA<AppwriteAccountFailure>()
                .having((failure) => failure.error, 'error', exception)
                .having(
                  (failure) => failure.kind,
                  'kind',
                  AppwriteFailureKind.conflict,
                ),
          ),
        );
        verifyNever(
          () => account.createEmailPasswordSession(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      });
    });

    group('currentAccount', () {
      test('M7.12 gives the account of the session', () async {
        final user = _MockUser();
        when(() => user.$id).thenReturn('u-1');
        when(() => user.email).thenReturn('a@x.local');
        when(() => user.name).thenReturn('A');
        when(() => account.get()).thenAnswer((_) async => user);

        final current = await apiClient.currentAccount();

        expect(current?.id, 'u-1');
        expect(current?.email, 'a@x.local');
        expect(current?.name, 'A');
      });

      test('M7.12 is null without a session', () async {
        when(() => account.get()).thenThrow(AppwriteException('guests', 401));

        expect(await apiClient.currentAccount(), isNull);
      });

      test('M7.12 fails when Appwrite cannot say', () async {
        when(() => account.get()).thenThrow(AppwriteException('down', 503));

        await expectLater(
          apiClient.currentAccount,
          throwsA(
            isA<AppwriteAccountFailure>().having(
              (failure) => failure.kind,
              'kind',
              AppwriteFailureKind.serverError,
            ),
          ),
        );
      });
    });

    group('signOut', () {
      test('M7.12 closes the current session', () async {
        when(() => account.deleteSession(sessionId: any(named: 'sessionId')))
            .thenAnswer((_) async {});

        await apiClient.signOut();

        verify(() => account.deleteSession(sessionId: 'current')).called(1);
      });

      test('M7.12 without a session the account is already signed out', () {
        when(() => account.deleteSession(sessionId: any(named: 'sessionId')))
            .thenThrow(AppwriteException('guests', 401));

        expect(apiClient.signOut(), completes);
      });

      test('M7.12 fails when Appwrite is unreachable', () async {
        when(() => account.deleteSession(sessionId: any(named: 'sessionId')))
            .thenThrow(AppwriteException('SocketException: no route'));

        await expectLater(
          apiClient.signOut,
          throwsA(
            isA<AppwriteAccountFailure>().having(
              (failure) => failure.kind,
              'kind',
              AppwriteFailureKind.unreachable,
            ),
          ),
        );
      });
    });

    test('M7.12 a sign-up, a sign-out and a lookup log no secret', () async {
      final records = <LogRecord>[];
      final previous = Logger.root.level;
      Logger.root.level = Level.ALL;
      final subscription = Logger.root.onRecord.listen(records.add);
      addTearDown(() async {
        await subscription.cancel();
        Logger.root.level = previous;
      });
      when(() => account.deleteSession(sessionId: any(named: 'sessionId')))
          .thenAnswer((_) async {});
      stubCreate();
      stubSession();
      final user = _MockUser();
      when(() => user.$id).thenReturn('u-1');
      when(() => user.email).thenReturn('private@x.local');
      when(() => user.name).thenReturn('Private Name');
      when(() => account.get()).thenAnswer((_) async => user);

      await apiClient.signUp(
        email: 'private@x.local',
        password: 'secret-123',
        name: 'Private Name',
      );
      await apiClient.currentAccount();
      await apiClient.signOut();

      expect(
        [for (final record in records) record.message],
        containsAll([
          'sign-up: started',
          'sign-up: done',
          'current account: done',
          'sign-out: done',
        ]),
      );
      for (final record in records) {
        expect(record.message, isNot(contains('secret-123')));
        expect(record.message, isNot(contains('private@x.local')));
        expect(record.message, isNot(contains('Private Name')));
      }
    });
  });

  group('findRows', () {
    late TablesDB tables;
    late AppwriteApiClient apiClient;

    setUp(() {
      tables = _MockTablesDB();
      apiClient = AppwriteApiClient.withClient(_MockClient(), tables: tables);
    });

    models.Row row(String id, Map<String, dynamic> data) => models.Row(
      $id: id,
      $sequence: '1',
      $tableId: 't',
      $databaseId: 'd',
      $createdAt: '',
      $updatedAt: '',
      $permissions: const [],
      data: data,
    );

    test(
      'M7.12 reads the rows that match, with their ID and columns',
      () async {
        when(
          () => tables.listRows(
            databaseId: any(named: 'databaseId'),
            tableId: any(named: 'tableId'),
            queries: any(named: 'queries'),
          ),
        ).thenAnswer(
          (_) async => models.RowList(
            total: 1,
            rows: [
              row('s-1', {'war_id': 'w-1'}),
            ],
          ),
        );

        final rows = await apiClient.findRows(
          databaseId: 'hawkbee',
          tableId: 'bt_sections',
          equal: {
            'account_id': ['a-1'],
          },
        );

        expect(rows, hasLength(1));
        expect(rows.single.id, 's-1');
        expect(rows.single.data['war_id'], 'w-1');
        final queries =
            verify(
                  () => tables.listRows(
                    databaseId: 'hawkbee',
                    tableId: 'bt_sections',
                    queries: captureAny(named: 'queries'),
                  ),
                ).captured.single
                as List<String>;
        expect(queries, [
          Query.equal('account_id', ['a-1']),
          Query.limit(100),
        ]);
      },
    );

    test('M7.12 fails with a $AppwriteRowsFailure', () async {
      when(
        () => tables.listRows(
          databaseId: any(named: 'databaseId'),
          tableId: any(named: 'tableId'),
          queries: any(named: 'queries'),
        ),
      ).thenThrow(AppwriteException('forbidden', 401));

      await expectLater(
        apiClient.findRows(databaseId: 'hawkbee', tableId: 'bt_sections'),
        throwsA(
          isA<AppwriteRowsFailure>().having(
            (failure) => failure.kind,
            'kind',
            AppwriteFailureKind.unauthorized,
          ),
        ),
      );
    });
  });

  group('execute', () {
    late Functions functions;
    late AppwriteApiClient apiClient;

    setUp(() {
      functions = _MockFunctions();
      apiClient = AppwriteApiClient.withClient(
        _MockClient(),
        functions: functions,
      );
    });

    models.Execution answer(int status, String body) {
      final execution = _MockExecution();
      when(() => execution.responseStatusCode).thenReturn(status);
      when(() => execution.responseBody).thenReturn(body);
      return execution;
    }

    void stubExecution(models.Execution execution) => when(
      () => functions.createExecution(
        functionId: any(named: 'functionId'),
        body: any(named: 'body'),
        xasync: any(named: 'xasync'),
      ),
    ).thenAnswer((_) async => execution);

    test('M7.12 runs the function with the body as JSON, and waits for its '
        'answer', () async {
      stubExecution(answer(200, '{"sectionId":"s-1"}'));

      final result = await apiClient.execute(
        functionId: 'bt_create_war',
        body: {'action': 'join', 'warId': 'w-1'},
      );

      expect(result.statusCode, 200);
      expect(result.body, {'sectionId': 's-1'});
      verify(
        () => functions.createExecution(
          functionId: 'bt_create_war',
          body: '{"action":"join","warId":"w-1"}',
          xasync: false,
        ),
      ).called(1);
    });

    test('M7.12 a function that refuses answers with its status and body: '
        'it is no failure', () async {
      stubExecution(answer(409, '{"error":"already_in_war"}'));

      final result = await apiClient.execute(functionId: 'bt_create_war');

      expect(result.statusCode, 409);
      expect(result.body, {'error': 'already_in_war'});
    });

    test(
      'M7.12 an answer that is not a JSON object is an empty body',
      () async {
        for (final text in ['', 'not json', '[1, 2]']) {
          stubExecution(answer(500, text));

          final result = await apiClient.execute(functionId: 'bt_create_war');

          expect(result.statusCode, 500);
          expect(result.body, isEmpty, reason: text);
        }
      },
    );

    test(
      'M7.12 fails with an $AppwriteExecutionFailure and its kind',
      () async {
        when(
          () => functions.createExecution(
            functionId: any(named: 'functionId'),
            body: any(named: 'body'),
            xasync: any(named: 'xasync'),
          ),
        ).thenThrow(AppwriteException('SocketException: no route'));

        await expectLater(
          apiClient.execute(functionId: 'bt_create_war'),
          throwsA(
            isA<AppwriteExecutionFailure>().having(
              (failure) => failure.kind,
              'kind',
              AppwriteFailureKind.unreachable,
            ),
          ),
        );
      },
    );

    test('M7.12 logs the run, never what the function was sent or '
        'answered', () async {
      final records = <LogRecord>[];
      final previous = Logger.root.level;
      Logger.root.level = Level.ALL;
      final subscription = Logger.root.onRecord.listen(records.add);
      addTearDown(() async {
        await subscription.cancel();
        Logger.root.level = previous;
      });
      stubExecution(answer(200, '{"sectionId":"s-private"}'));

      await apiClient.execute(
        functionId: 'bt_create_war',
        body: {'warId': 'w-private'},
      );

      expect([
        for (final record in records) record.message,
      ], equals(['run function: started', 'run function: done']));
    });
  });

  group(AppwriteFailureKind, () {
    for (final (code, kind) in [
      (400, AppwriteFailureKind.invalidInput),
      (401, AppwriteFailureKind.unauthorized),
      (409, AppwriteFailureKind.conflict),
      (429, AppwriteFailureKind.tooManyRequests),
      (500, AppwriteFailureKind.serverError),
      (503, AppwriteFailureKind.serverError),
      (404, AppwriteFailureKind.other),
      (null, AppwriteFailureKind.unreachable),
    ]) {
      test('M7.12 is read from the status $code as $kind', () async {
        final account = _MockAccount();
        when(account.createJWT).thenThrow(AppwriteException('x', code));
        final apiClient = AppwriteApiClient.withClient(
          _MockClient(),
          account: account,
        );

        await expectLater(
          apiClient.createJwt,
          throwsA(
            isA<AppwriteSignInFailure>().having(
              (failure) => failure.kind,
              'kind',
              kind,
            ),
          ),
        );
      });
    }

    test("M7.12 an error that is not Appwrite's is other", () async {
      final account = _MockAccount();
      when(account.createJWT).thenThrow(StateError('x'));
      final apiClient = AppwriteApiClient.withClient(
        _MockClient(),
        account: account,
      );

      await expectLater(
        apiClient.createJwt,
        throwsA(
          isA<AppwriteSignInFailure>().having(
            (failure) => failure.kind,
            'kind',
            AppwriteFailureKind.other,
          ),
        ),
      );
    });

    test('M7.12 a failure made without a kind is other', () {
      expect(const AppwriteAccountFailure('x').kind, AppwriteFailureKind.other);
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

  group(AppwriteAccountFailure, () {
    test('describes the underlying error', () {
      expect(
        const AppwriteAccountFailure('boom').toString(),
        'AppwriteAccountFailure: boom',
      );
    });
  });

  group(AppwriteExecutionFailure, () {
    test('describes the underlying error', () {
      expect(
        const AppwriteExecutionFailure('boom').toString(),
        'AppwriteExecutionFailure: boom',
      );
    });
  });

  group(AppwriteRowsFailure, () {
    test('describes the underlying error', () {
      expect(
        const AppwriteRowsFailure('boom').toString(),
        'AppwriteRowsFailure: boom',
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
