import 'package:flutter/foundation.dart' show immutable;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

@immutable
class Task {
  const Task({
    required this.id,
    required this.description,
    this.done = false,
  });

  final String id;
  final String description;
  final bool done;
}

class TaskList extends Notifier<List<Task>> {
  @override
  List<Task> build() => [];

  void add(String description) {
    state = [
      ...state,
      Task(id: _uuid.v4(), description: description),
    ];
  }

  void toggle(String id) {
    state = [
      for (final task in state)
        if (task.id == id)
          Task(id: task.id, description: task.description, done: !task.done)
        else
          task
    ];
  }

  void edit({required String id, required String description}) {
    state = [
      for (final task in state)
        if (task.id == id)
          Task(id: task.id, description: description, done: task.done)
        else
          task
    ];
  }

  void remove(String id) {
    state = state.where((task) => task.id != id).toList();
  }
}
