import 'package:backend_status_repository/backend_status_repository.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hawkbee/backend_status/backend_status.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

class _MockBackendStatusCubit extends MockCubit<BackendStatusState>
    implements BackendStatusCubit;

void main() {
  group(BackendStatusPage, () {
    late BackendStatusRepository backendStatusRepository;

    setUp(() {
      backendStatusRepository = MockBackendStatusRepository();
      when(() => backendStatusRepository.checkConnection())
          .thenAnswer((_) async {});
    });

    testWidgets('checks the connection on start', (tester) async {
      await tester.pumpApp(
        const BackendStatusPage(),
        backendStatusRepository: backendStatusRepository,
      );

      expect(find.byType(BackendStatusView), findsOneWidget);
      verify(() => backendStatusRepository.checkConnection()).called(1);
    });
  });

  group(BackendStatusView, () {
    late BackendStatusCubit cubit;

    setUp(() {
      cubit = _MockBackendStatusCubit();
      when(() => cubit.checkConnection()).thenAnswer((_) async {});
    });

    Future<void> pumpView(WidgetTester tester, BackendStatusState state) {
      when(() => cubit.state).thenReturn(state);
      return tester.pumpApp(
        BlocProvider.value(value: cubit, child: const BackendStatusView()),
      );
    }

    testWidgets('shows a progress indicator while checking', (tester) async {
      await pumpView(
        tester,
        const BackendStatusState(status: BackendStatus.checking),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Contacting Appwrite…'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows that the backend is reachable', (tester) async {
      await pumpView(
        tester,
        const BackendStatusState(status: BackendStatus.reachable),
      );

      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
      expect(find.text('Connected to Appwrite'), findsOneWidget);
    });

    testWidgets('shows the reason when the backend is unreachable', (
      tester,
    ) async {
      await pumpView(
        tester,
        const BackendStatusState(
          status: BackendStatus.unreachable,
          errorMessage: 'Project not found',
        ),
      );

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.text('Cannot reach Appwrite'), findsOneWidget);
      expect(find.text('Project not found'), findsOneWidget);
    });

    testWidgets('checks again when the retry button is tapped', (tester) async {
      await pumpView(
        tester,
        const BackendStatusState(status: BackendStatus.unreachable),
      );

      await tester.tap(find.text('Check again'));

      verify(() => cubit.checkConnection()).called(1);
    });
  });
}
