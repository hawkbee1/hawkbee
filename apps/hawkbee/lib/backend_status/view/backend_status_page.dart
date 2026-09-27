import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hawkbee/backend_status/backend_status.dart';
import 'package:hawkbee/l10n/l10n.dart';
import 'package:material_ui/material_ui.dart';

class BackendStatusPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = BackendStatusCubit(
          backendStatusRepository: context.read(),
        );
        unawaited(cubit.checkConnection());
        return cubit;
      },
      child: const BackendStatusView(),
    );
  }
}

class BackendStatusView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = context.watch<BackendStatusCubit>().state;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              switch (state.status) {
                BackendStatus.initial ||
                BackendStatus.checking => const CircularProgressIndicator(),
                BackendStatus.reachable => Icon(
                  Icons.cloud_done,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                BackendStatus.unreachable => Icon(
                  Icons.cloud_off,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
              },
              const SizedBox(height: 16),
              Text(
                switch (state.status) {
                  BackendStatus.initial ||
                  BackendStatus.checking => l10n.backendStatusChecking,
                  BackendStatus.reachable => l10n.backendStatusReachable,
                  BackendStatus.unreachable => l10n.backendStatusUnreachable,
                },
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (state.errorMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                SelectableText(
                  state.errorMessage,
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: state.status == BackendStatus.checking
                    ? null
                    : context.read<BackendStatusCubit>().checkConnection,
                child: Text(l10n.backendStatusRetryButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
