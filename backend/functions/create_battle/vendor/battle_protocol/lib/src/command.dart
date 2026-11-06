import 'package:battle_protocol/src/orders.dart';
import 'package:battle_protocol/src/values.dart';
import 'package:equatable/equatable.dart';

/// {@template command}
/// One order with who sent it, when, and where it stands in the battle
/// (Command pattern, stack decision 7): logged, replayed from the log and
/// sent over the socket (stack decisions 2 and 3).
///
/// The sender states [sender], [sentAt] and [order]. The host checks the
/// sender against how it signed in, then stamps the [origin] that sign-in
/// gives (AI-05, decisions 162 and 166) and its [seq] (stack decision 8):
/// both are null until then.
/// {@endtemplate}
final class Command extends Equatable {
  /// {@macro command}
  const new({
    required this.sender,
    required this.sentAt,
    required this.order,
    this.origin,
    this.seq,
  });

  /// The account and section that send it.
  final Sender sender;

  /// The sender's battle time when it sent the order.
  final Duration sentAt;

  /// What to do.
  final Order order;

  /// Who acted: player, AI or server; set by the host.
  final Origin? origin;

  /// The host's sequence number, from 1 in each battle; set by the host.
  final int? seq;

  /// This command as the host accepts it: with its [origin] and [seq].
  Command stamped({required Origin origin, required int seq}) => Command(
    sender: sender,
    sentAt: sentAt,
    order: order,
    origin: origin,
    seq: seq,
  );

  @override
  List<Object?> get props => [sender, sentAt, order, origin, seq];
}
