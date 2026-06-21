import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/project.dart';
import '../../models/task.dart';
import '../../providers/project_provider.dart';

class AdminView extends StatelessWidget {
  const AdminView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final totalTasks = provider.projects.fold<int>(
      0,
      (count, project) => count + project.tasks.length,
    );
    final completed = provider.projects.fold<int>(
      0,
      (count, project) => count + project.tasks.where((task) => task.status == TaskStatus.done).length,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Admin workspace')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricCard(label: 'Users', value: '${provider.users.length}'),
              _MetricCard(label: 'Projects', value: '${provider.projects.length}'),
              _MetricCard(label: 'Tasks', value: '$totalTasks'),
              _MetricCard(label: 'Completed', value: '$completed'),
            ],
          ),
          const SizedBox(height: 22),
          Text('Project permissions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final project in provider.projects) _ProjectPermissions(project: project),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white60)),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectPermissions extends StatelessWidget {
  const _ProjectPermissions({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(project.name),
        subtitle: Text('${project.members.length} members'),
        children: [
          for (final member in project.members)
            ListTile(
              title: Text(provider.userById(member.userId)?.name ?? member.email),
              subtitle: Text(member.email),
              leading: Icon(
                member.permission == ProjectPermission.owner
                    ? Icons.workspace_premium_outlined
                    : Icons.person_outline,
              ),
              trailing: member.userId == project.managerId
                  ? const Chip(label: Text('Manager'))
                  : TextButton(
                      onPressed: () => provider.setManager(project, member.userId),
                      child: const Text('Make manager'),
                    ),
            ),
        ],
      ),
    );
  }
}
