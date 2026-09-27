import 'package:backend_status_repository/backend_status_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hawkbee/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class MockBackendStatusRepository extends Mock
    implements BackendStatusRepository;

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    BackendStatusRepository? backendStatusRepository,
  }) {
    return pumpWidget(
      RepositoryProvider.value(
        value: backendStatusRepository ?? MockBackendStatusRepository(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: widget,
        ),
      ),
    );
  }
}
