import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../models/task.dart';
import '../providers/project_provider.dart';
import '../views/project/project_detail_view.dart';

class TaskListPanel extends StatelessWidget {
  const TaskListPanel({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: project.tasks.length + 1,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == 0) {
            return const ListTile(
              title: Text('Tasks'),
              subtitle: Text('Tap a task to discuss, attach files, or update status.'),
            );
          }
          final task = project.tasks[index - 1];
          final assignee = context.read<ProjectProvider>().userById(task.assigneeId);
          return ListTile(
            leading: const Icon(Icons.check_circle_outline),
            title: Text(task.title),
            subtitle: Text('${task.status.label} • ${assignee?.name ?? 'Unassigned'}'),
            trailing: Wrap(
              spacing: 8,
              children: [
                Text('${task.comments.length} comments'),
                Text('${task.attachments.length} files'),
              ],
            ),
            onTap: () => ProjectDetailView.openTaskSheet(context, project, task),
          );
        },
      ),
    );
  }
}
