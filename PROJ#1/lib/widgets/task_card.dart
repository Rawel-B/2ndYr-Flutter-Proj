import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../models/task.dart';
import '../providers/project_provider.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.project,
    required this.task,
    required this.onTap,
  });

  final Project project;
  final ProjectTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final users = context.read<ProjectProvider>();
    final assignee = users.userById(task.assigneeId);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task.title, style: const TextStyle(fontWeight: FontWeight.w800)),
              if (task.flags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final flag in task.flags)
                      Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(_flagIcon(flag), size: 14),
                        label: Text(flag.label),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Text(
                task.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(project.color),
                    child: Text(
                      (assignee?.name ?? '?').characters.first.toUpperCase(),
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      assignee?.name ?? 'Unassigned',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white60),
                    ),
                  ),
                  if (task.dueDate != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.event_outlined, size: 16, color: Colors.white.withAlpha(150)),
                    const SizedBox(width: 3),
                    Text(DateFormat.MMMd().format(task.dueDate!)),
                  ],
                  Icon(Icons.mode_comment_outlined, size: 16, color: Colors.white.withAlpha(150)),
                  const SizedBox(width: 3),
                  Text('${task.comments.length}'),
                  const SizedBox(width: 8),
                  Icon(Icons.attach_file, size: 16, color: Colors.white.withAlpha(150)),
                  const SizedBox(width: 3),
                  Text('${task.attachments.length}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _flagIcon(TaskFlag flag) {
    return switch (flag) {
      TaskFlag.urgent => Icons.priority_high,
      TaskFlag.blocked => Icons.block,
      TaskFlag.review => Icons.rate_review_outlined,
      TaskFlag.client => Icons.handshake_outlined,
    };
  }
}
