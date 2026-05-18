import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../models/task.dart';
import '../providers/project_provider.dart';
import 'task_card.dart';

class KanbanColumn extends StatelessWidget {
  const KanbanColumn({
    super.key,
    required this.project,
    required this.status,
    required this.onAddTask,
    required this.onOpenTask,
  });

  final Project project;
  final TaskStatus status;
  final VoidCallback onAddTask;
  final ValueChanged<ProjectTask> onOpenTask;

  @override
  Widget build(BuildContext context) {
    final tasks = project.tasks.where((task) => task.status == status).toList();
    return DragTarget<ProjectTask>(
      onWillAcceptWithDetails: (details) => details.data.status != status,
      onAcceptWithDetails: (details) {
        context.read<ProjectProvider>().moveTask(project, details.data, status);
      },
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hovering ? const Color(0xFF182536) : const Color(0xFF101722),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hovering ? Theme.of(context).colorScheme.primary : const Color(0xFF1E293B),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(status.label, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: Colors.white10,
                    child: Text('${tasks.length}', style: const TextStyle(fontSize: 12)),
                  ),
                  IconButton(
                    tooltip: 'Add task',
                    onPressed: onAddTask,
                    icon: const Icon(Icons.add, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(child: _TaskStack(tasks: tasks, project: project, onOpenTask: onOpenTask)),
            ],
          ),
        );
      },
    );
  }
}

class _TaskStack extends StatelessWidget {
  const _TaskStack({
    required this.tasks,
    required this.project,
    required this.onOpenTask,
  });

  final List<ProjectTask> tasks;
  final Project project;
  final ValueChanged<ProjectTask> onOpenTask;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(
        child: Text('Drop tasks here', style: TextStyle(color: Colors.white38)),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      itemCount: tasks.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return LongPressDraggable<ProjectTask>(
          data: task,
          feedback: SizedBox(
            width: 280,
            child: Material(
              color: Colors.transparent,
              child: TaskCard(project: project, task: task, onTap: () {}),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.35,
            child: TaskCard(project: project, task: task, onTap: () {}),
          ),
          child: TaskCard(
            project: project,
            task: task,
            onTap: () => onOpenTask(task),
          ),
        );
      },
    );
  }
}
