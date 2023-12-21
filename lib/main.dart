import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'task.dart';

final addTaskKey = UniqueKey();
final activeFilterKey = UniqueKey();
final completedFilterKey = UniqueKey();
final allFilterKey = UniqueKey();

final taskListProvider = NotifierProvider<TaskList, List<Task>>(TaskList.new);

enum TaskListFilter { all, active, completed }

final taskListFilter = StateProvider((ref) => TaskListFilter.all);

final uncompletedTaskCount = Provider<int>((ref) {
  return ref.watch(taskListProvider).where((task) => !task.done).length;
});

final filteredTasks = Provider<List<Task>>((ref) {
  final filter = ref.watch(taskListFilter);
  final tasks = ref.watch(taskListProvider);

  switch (filter) {
    case TaskListFilter.completed:
      return tasks.where((task) => task.done).toList();
    case TaskListFilter.active:
      return tasks.where((task) => !task.done).toList();
    case TaskListFilter.all:
      return tasks;
  }
});

final _currentTask = Provider<Task>((ref) => throw UnimplementedError());

void main() {
  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends HookConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(filteredTasks);
    final newTaskController = useTextEditingController();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 40,
          ),
          children: <Widget>[
            const Title(),
            TextField(
              key: addTaskKey,
              controller: newTaskController,
              decoration: const InputDecoration(
                labelText: 'O que será feito a seguir?',
              ),
              onSubmitted: (value) {
                ref.read(taskListProvider.notifier).add(value);
                newTaskController.clear();
              },
            ),
            const SizedBox(
              height: 42,
            ),
            const Toolbar(),
            if (tasks.isNotEmpty)
              const Divider(
                height: 0,
              ),
            for (var i = 0; i < tasks.length; i++) ...[
              if (i > 0)
                const Divider(
                  height: 0,
                ),
              Dismissible(
                key: ValueKey(tasks[i].id),
                onDismissed: (direction) {
                  ref.read(taskListProvider.notifier).remove(tasks[i].id);
                },
                child: ProviderScope(
                  overrides: [
                    _currentTask.overrideWithValue(tasks[i]),
                  ],
                  child: const TaskItem(),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class Toolbar extends HookConsumerWidget {
  const Toolbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(taskListFilter);

    Color? textColorFor(TaskListFilter value) {
      return filter == value ? Colors.blue : Colors.black;
    }

    return Material(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Text(
              '${ref.watch(uncompletedTaskCount)} tarefas restantes',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Tooltip(
            key: allFilterKey,
            message: 'Todas as tarefas',
            child: TextButton(
              onPressed: () {
                ref.read(taskListFilter.notifier).state = TaskListFilter.all;
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: MaterialStateProperty.all(
                  textColorFor(TaskListFilter.all),
                ),
              ),
              child: const Text('Todas'),
            ),
          ),
          Tooltip(
            key: activeFilterKey,
            message: 'Apenas tarefas não concluídas',
            child: TextButton(
              onPressed: () {
                ref.read(taskListFilter.notifier).state = TaskListFilter.active;
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: MaterialStateProperty.all(
                  textColorFor(TaskListFilter.active),
                ),
              ),
              child: const Text('Ativas'),
            ),
          ),
          Tooltip(
            key: completedFilterKey,
            message: 'Apenas tarefas concluídas',
            child: TextButton(
              onPressed: () {
                ref.read(taskListFilter.notifier).state =
                    TaskListFilter.completed;
              },
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: MaterialStateProperty.all(
                  textColorFor(TaskListFilter.completed),
                ),
              ),
              child: const Text('Concluídas'),
            ),
          ),
        ],
      ),
    );
  }
}

class Title extends StatelessWidget {
  const Title({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Lista de tarefas',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color.fromARGB(38, 47, 47, 247),
        fontSize: 100,
        fontWeight: FontWeight.w100,
        fontFamily: 'Helvetica Neue',
      ),
    );
  }
}

class TaskItem extends HookConsumerWidget {
  const TaskItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref.watch(_currentTask);
    final itemFocusNode = useFocusNode();
    final itemIsFocused = useIsFocused(itemFocusNode);

    final textEditingController = useTextEditingController();
    final textFieldFocusNode = useFocusNode();

    return Material(
      color: Colors.white,
      elevation: 6,
      child: Focus(
        focusNode: itemFocusNode,
        onFocusChange: (focused) {
          if (focused) {
            textEditingController.text = task.description;
          } else {
            ref
                .read(taskListProvider.notifier)
                .edit(id: task.id, description: task.description);
          }
        },
        child: ListTile(
          onTap: () {
            itemFocusNode.requestFocus();
            textFieldFocusNode.requestFocus();
          },
          leading: Checkbox(
            value: task.done,
            onChanged: (value) {
              ref.read(taskListProvider.notifier).toggle(task.id);
            },
          ),
          title: itemIsFocused
              ? TextField(
                  autofocus: true,
                  focusNode: textFieldFocusNode,
                  controller: textEditingController,
                )
              : Text(
                  task.description,
                ),
        ),
      ),
    );
  }
}

bool useIsFocused(FocusNode node) {
  final isFocused = useState(node.hasFocus);

  useEffect(() {
    void listener() {
      isFocused.value = node.hasFocus;
    }

    node.addListener(listener);
    return () {
      node.removeListener(listener);
    };
  }, [node]);

  return isFocused.value;
}
