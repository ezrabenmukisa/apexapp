import 'dart:async';

import 'package:injectable/injectable.dart';

/// What kind of server data changed.
enum DataTopic {
  projects,
  milestones,
  evidence,
  members,
  notifications,
  outbox,
}

/// App-wide "something changed" bus. Repositories publish after a
/// successful mutation; cubits on other screens listen and reload, so e.g.
/// approving evidence updates the Projects tab and the Review badge.
@lazySingleton
class DataChanges {
  final _controller = StreamController<DataTopic>.broadcast();

  Stream<DataTopic> get stream => _controller.stream;

  Stream<DataTopic> on(Set<DataTopic> topics) => stream.where(topics.contains);

  void publish(DataTopic topic) => _controller.add(topic);

  @disposeMethod
  Future<void> dispose() => _controller.close();
}
