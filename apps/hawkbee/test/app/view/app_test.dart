import 'package:backend_status_repository/backend_status_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hawkbee/app/app.dart';
import 'package:hawkbee/backend_status/backend_status.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/helpers.dart';

void main() {
  group(App, () {
    late BackendStatusRepository backendStatusRepository;

    setUp(() {
      backendStatusRepository = MockBackendStatusRepository();
      when(() => backendStatusRepository.checkConnection())
          .thenAnswer((_) async {});
    });

    testWidgets('renders $BackendStatusPage', (tester) async {
      await tester.pumpWidget(
        App(backendStatusRepository: backendStatusRepository),
      );

      expect(find.byType(BackendStatusPage), findsOneWidget);
    });
  });
}
