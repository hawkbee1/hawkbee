import 'package:battle_protocol/src/command.dart';
import 'package:battle_protocol/src/events.dart';
import 'package:equatable/equatable.dart';

/// {@template log_entry}
/// One entry of the battle log (stack decision 2) at the battle time [at]:
/// a [command] the host accepted, stamped with its origin and sequence
/// number, with the [events] it caused at once; or, without a command, the
/// [events] the host produced on its own (a waiting order carried out, a
/// timer, a capture, the end of the battle).
///
/// Replaying the commands at their times gives the battle again; the
/// events let statistics read the log without a replay.
/// {@endtemplate}
final class LogEntry extends Equatable {
  /// {@macro log_entry}
  const new({required this.at, required this.events, this.command});

  /// The battle time.
  final Duration at;

  /// The accepted command; null for the host's own events.
  final Command? command;

  /// What happened.
  final List<BattleEvent> events;

  @override
  List<Object?> get props => [at, command, events];
}
