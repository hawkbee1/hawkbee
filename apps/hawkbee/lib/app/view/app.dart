import 'package:backend_status_repository/backend_status_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hawkbee/backend_status/backend_status.dart';
import 'package:hawkbee/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

class App extends StatelessWidget {
  const new({required this._backendStatusRepository, super.key});

  final BackendStatusRepository _backendStatusRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: _backendStatusRepository,
      child: const AppView(),
    );
  }
}

class AppView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const BackendStatusPage(),
    );
  }
}
