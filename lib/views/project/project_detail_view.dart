import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
            tooltip: provider.activityVisible ? 'Hide activity' : 'Show activity',
            onPressed: () {
              if (MediaQuery.sizeOf(context).width >= 1100) {
                provider.toggleActivityPanel();
              } else {
                _showActivity(context, project);
              }
            },
            icon: Icon(
              provider.activityVisible ? Icons.history_toggle_off : Icons.history,
            ),
          ),
          IconButton(
            tooltip: 'Add task',
            onPressed: () => _taskDialog(context, project),
            icon: const Icon(Icons.add_task),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showSidePanel = constraints.maxWidth >= 1100 && provider.activityVisible;
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
        onPressed: () => _taskDialog(context, project),
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
      builder: (sheetContext) {
        final provider = sheetContext.watch<ProjectProvider>();
        final freshProject = provider.projects.firstWhere((item) => item.id == project.id);
        final freshTask = freshProject.tasks.firstWhere((item) => item.id == task.id);
        final assignee = provider.userById(freshTask.assigneeId);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            0,
            20,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      freshTask.title,
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit task',
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _taskDialog(context, freshProject, task: freshTask);
                    },
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete task',
                    onPressed: () => _deleteTask(sheetContext, freshProject, freshTask),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(freshTask.description, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(freshTask.status.label)),
                  Chip(label: Text('Assigned to ${assignee?.name ?? 'Unassigned'}')),
                  if (freshTask.dueDate != null)
                    Chip(label: Text('Due ${DateFormat.MMMd().format(freshTask.dueDate!)}')),
                  for (final flag in freshTask.flags)
                    Chip(
                      avatar: Icon(_flagIcon(flag), size: 16),
                      label: Text(flag.label),
                    ),
                  Chip(label: Text('${freshTask.attachments.length} attachments')),
                ],
              ),
              const SizedBox(height: 20),
              Text('Comments', style: Theme.of(sheetContext).textTheme.titleMedium),
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

  static void _showActivity(BuildContext context, Project project) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.72,
        child: ActivityPanel(project: project),
      ),
    );
  }

  static void _deleteTask(BuildContext context, Project project, ProjectTask task) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('This will remove "${task.title}" from the project.'),
        actions: [
          TextButton(onPressed: Navigator.of(dialogContext).pop, child: const Text('Cancel')),
          FilledButton.tonalIcon(
            onPressed: () {
              context.read<ProjectProvider>().deleteTask(project, task);
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  static void _taskDialog(
    BuildContext context,
    Project project, {
    TaskStatus? status,
    ProjectTask? task,
  }) {
    final title = TextEditingController(text: task?.title);
    final description = TextEditingController(text: task?.description);
    var assigneeId = project.members.first.userId;
    var taskStatus = task?.status ?? status ?? TaskStatus.todo;
    var dueDate = task?.dueDate;
    var selectedFlags = {...?task?.flags};
    if (task != null) {
      assigneeId = task.assigneeId;
    }

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final provider = context.read<ProjectProvider>();
          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          task == null ? Icons.add_task : Icons.edit_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            task == null ? 'New task' : 'Edit task',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: Navigator.of(context).pop,
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: title,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: description,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                      minLines: 3,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<TaskStatus>(
                      initialValue: taskStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: [
                        for (final item in TaskStatus.values)
                          DropdownMenuItem(value: item, child: Text(item.label)),
                      ],
                      onChanged: (value) => setState(() => taskStatus = value ?? taskStatus),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: assigneeId,
                      decoration: const InputDecoration(
                        labelText: 'Assignee',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      items: [
                        for (final member in project.members)
                          DropdownMenuItem(
                            value: member.userId,
                            child: Text(provider.userById(member.userId)?.name ?? member.email),
                          ),
                      ],
                      onChanged: (value) => setState(() => assigneeId = value ?? assigneeId),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() => dueDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due date',
                          prefixIcon: Icon(Icons.event_outlined),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                dueDate == null
                                    ? 'No due date'
                                    : DateFormat.yMMMd().format(dueDate!),
                              ),
                            ),
                            if (dueDate != null)
                              IconButton(
                                tooltip: 'Clear due date',
                                onPressed: () => setState(() => dueDate = null),
                                icon: const Icon(Icons.close),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Flags', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final flag in TaskFlag.values)
                          FilterChip(
                            avatar: Icon(_flagIcon(flag), size: 16),
                            label: Text(flag.label),
                            selected: selectedFlags.contains(flag),
                            onSelected: (selected) => setState(() {
                              selected ? selectedFlags.add(flag) : selectedFlags.remove(flag);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        TextButton(
                          onPressed: Navigator.of(context).pop,
                          child: const Text('Cancel'),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (title.text.trim().isEmpty) return;
                            if (task == null) {
                              provider.createTask(
                                project: project,
                                title: title.text,
                                description: description.text,
                                status: taskStatus,
                                assigneeId: assigneeId,
                                dueDate: dueDate,
                                flags: selectedFlags.toList(growable: false),
                              );
                            } else {
                              provider.updateTask(
                                project,
                                task.copyWith(
                                  title: title.text.trim(),
                                  description: description.text.trim(),
                                  status: taskStatus,
                                  assigneeId: assigneeId,
                                  dueDate: dueDate,
                                  clearDueDate: dueDate == null,
                                  flags: selectedFlags.toList(growable: false),
                                ),
                              );
                            }
                            Navigator.of(context).pop();
                          },
                          icon: Icon(task == null ? Icons.add : Icons.save_outlined),
                          label: Text(task == null ? 'Create' : 'Save'),
                        ),
                      ],
                    ),
                  ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static IconData _flagIcon(TaskFlag flag) {
    return switch (flag) {
      TaskFlag.urgent => Icons.priority_high,
      TaskFlag.blocked => Icons.block,
      TaskFlag.review => Icons.rate_review_outlined,
      TaskFlag.client => Icons.handshake_outlined,
    };
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
              onAddTask: () => ProjectDetailView._taskDialog(
                context,
                project,
                status: status,
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
