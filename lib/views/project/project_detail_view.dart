import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/project.dart';
import '../../models/task.dart';
import '../../providers/project_provider.dart';
import '../../widgets/activity_panel.dart';
import '../../widgets/kanban_column.dart';
import '../../widgets/task_list_view.dart';

class ProjectDetailView extends StatelessWidget {
  const ProjectDetailView({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final project = provider.projects.firstWhere((item) => item.id == projectId);

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            tooltip: provider.listView ? 'Kanban view' : 'List view',
            onPressed: provider.toggleView,
            icon: Icon(provider.listView ? Icons.view_kanban_outlined : Icons.list_alt),
          ),
          IconButton(
            tooltip: 'Invite member',
            onPressed: () => _invite(context, project),
            icon: const Icon(Icons.person_add_alt),
          ),
          IconButton(
            tooltip: 'Add task',
            onPressed: () => _taskDialog(context, project, TaskStatus.todo),
            icon: const Icon(Icons.add_task),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showSidePanel = constraints.maxWidth >= 1100;
            return Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: provider.listView
                        ? TaskListPanel(project: project)
                        : _Board(project: project),
                  ),
                ),
                if (showSidePanel)
                  SizedBox(
                    width: 340,
                    child: ActivityPanel(project: project),
                  ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add task',
        onPressed: () => _taskDialog(context, project, TaskStatus.todo),
        child: const Icon(Icons.add),
      ),
    );
  }

  static void openTaskSheet(
    BuildContext context,
    Project project,
    ProjectTask task,
  ) {
    final comment = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final provider = context.watch<ProjectProvider>();
        final freshProject = provider.projects.firstWhere((item) => item.id == project.id);
        final freshTask = freshProject.tasks.firstWhere((item) => item.id == task.id);
        final assignee = provider.userById(freshTask.assigneeId);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text(freshTask.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(freshTask.description, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(freshTask.status.label)),
                  Chip(label: Text('Assigned to ${assignee?.name ?? 'Unassigned'}')),
                  Chip(label: Text('${freshTask.attachments.length} attachments')),
                ],
              ),
              const SizedBox(height: 20),
              Text('Comments', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final item in freshTask.comments)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: Text(provider.userById(item.authorId)?.name ?? 'Unknown'),
                  subtitle: Text(item.message),
                ),
              const SizedBox(height: 10),
              TextField(
                controller: comment,
                decoration: const InputDecoration(
                  labelText: 'Add a comment',
                  prefixIcon: Icon(Icons.mode_comment_outlined),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.pickFiles();
                        final file = result?.files.single;
                        if (file == null) return;
                        provider.addAttachment(
                          freshProject,
                          freshTask,
                          file.name,
                          file.path ?? file.name,
                        );
                      },
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Attach file'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        provider.addComment(freshProject, freshTask, comment.text);
                        comment.clear();
                      },
                      icon: const Icon(Icons.send),
                      label: const Text('Comment'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _invite(BuildContext context, Project project) {
    final email = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite member'),
        content: TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email or UID'),
        ),
        actions: [
          TextButton(onPressed: Navigator.of(context).pop, child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              context.read<ProjectProvider>().inviteMember(project, email.text);
              Navigator.of(context).pop();
            },
            child: const Text('Invite'),
          ),
        ],
      ),
    );
  }

  void _taskDialog(BuildContext context, Project project, TaskStatus status) {
    final title = TextEditingController();
    final description = TextEditingController();
    var assigneeId = project.members.first.userId;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final provider = context.read<ProjectProvider>();
          return AlertDialog(
            title: const Text('New task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: assigneeId,
                  decoration: const InputDecoration(labelText: 'Assignee'),
                  items: [
                    for (final member in project.members)
                      DropdownMenuItem(
                        value: member.userId,
                        child: Text(provider.userById(member.userId)?.name ?? member.email),
                      ),
                  ],
                  onChanged: (value) => setState(() => assigneeId = value ?? assigneeId),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: Navigator.of(context).pop, child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  if (title.text.trim().isEmpty) return;
                  context.read<ProjectProvider>().createTask(
                        project: project,
                        title: title.text,
                        description: description.text,
                        status: status,
                        assigneeId: assigneeId,
                      );
                  Navigator.of(context).pop();
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final children = [
          for (final status in TaskStatus.values)
            KanbanColumn(
              project: project,
              status: status,
              onAddTask: () => ProjectDetailView(projectId: project.id)._taskDialog(
                context,
                project,
                status,
              ),
              onOpenTask: (task) => ProjectDetailView.openTaskSheet(context, project, task),
            ),
        ];
        if (compact) {
          return ListView.separated(
            itemCount: children.length,
            separatorBuilder: (context, index) => const SizedBox(height: 14),
            itemBuilder: (_, index) => SizedBox(height: 460, child: children[index]),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final child in children)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: child,
                ),
              ),
          ],
        );
      },
    );
  }
}
