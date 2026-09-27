import 'dart:async';
import 'dart:developer';

import 'package:appwrite_api_client/appwrite_api_client.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';

class AppBlocObserver extends BlocObserver {
  const new();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

/// Appwrite settings passed at build time with
/// `--dart-define-from-file=../../env/<flavor>.json`.
const _appwriteEndpoint = String.fromEnvironment('APPWRITE_ENDPOINT');
const _appwriteProjectId = String.fromEnvironment('APPWRITE_PROJECT_ID');

Future<void> bootstrap(
  FutureOr<Widget> Function(AppwriteApiClient apiClient) builder,
) async {
  // The Appwrite client reads the documents directory as soon as it is built.
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  if (_appwriteEndpoint.isEmpty || _appwriteProjectId.isEmpty) {
    throw StateError(
      'APPWRITE_ENDPOINT and APPWRITE_PROJECT_ID are not set. Run with '
      '--dart-define-from-file=../../env/<flavor>.json',
    );
  }

  final apiClient = AppwriteApiClient(
    endpoint: _appwriteEndpoint,
    projectId: _appwriteProjectId,
  );

  runApp(await builder(apiClient));
}
