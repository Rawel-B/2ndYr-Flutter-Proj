import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../providers/auth_provider.dart';
import '../../providers/project_provider.dart';
import '../admin/admin_view.dart';
import '../mockup/mockup_view.dart';
import '../project/project_detail_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final projects = context.watch<ProjectProvider>();
    final user = auth.user!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FlutterTrello'),
        actions: [
          IconButton(
            tooltip: 'Visual mockup',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MockupView()),
            ),
            icon: const Icon(Icons.draw_outlined),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _showNotifications(context),
            icon: Badge(
              isLabelVisible: projects.unreadNotifications > 0,
              label: Text('${projects.unreadNotifications}'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          if (user.isAdmin)
            IconButton(
              tooltip: 'Admin',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminView()),
              ),
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: context.read<AuthProvider>().signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateProject(context),
        icon: const Icon(Icons.add),
        label: const Text('Project'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final project = projects.selectedProject;
            return Row(
              children: [
                SizedBox(
                  width: wide ? 340 : constraints.maxWidth,
                  child: _ProjectList(user: user),
                ),
                if (wide)
                  Expanded(
                    child: project == null
                        ? const _EmptyState()
                        : ProjectDetailView(projectId: project.id),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    final provider = context.read<ProjectProvider>()..markNotificationsRead();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          Text('Notifications', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final notification in provider.notifications)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.circle_notifications_outlined),
              title: Text(notification.title),
              subtitle: Text(notification.body),
            ),
        ],
      ),
    );
  }

  void _showCreateProject(BuildContext context) {
    final name = TextEditingController();
    final description = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New project'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: Navigator.of(context).pop, child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (name.text.trim().isEmpty) return;
              context.read<ProjectProvider>().createProject(name.text, description.text);
              Navigator.of(context).pop();
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _ProjectList extends StatelessWidget {
  const _ProjectList({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Text('Hello, ${user.name}', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          provider.isFirebaseReady ? 'Firebase connected' : 'Demo mode until Firebase is configured',
          style: const TextStyle(color: Colors.white60),
        ),
        const SizedBox(height: 22),
        for (final project in provider.projects)
          _ProjectCard(
            project: project,
            selected: provider.selectedProject?.id == project.id,
            onTap: () {
              provider.selectProject(project.id);
              if (MediaQuery.sizeOf(context).width < 900) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProjectDetailView(projectId: project.id),
                  ),
                );
              }
            },
          ),
      ],
    );
  }
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.selected,
    required this.onTap,
  });

  final Project project;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = project.tasks.where((task) => task.status == TaskStatus.done).length;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(project.color),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  Text('${project.members.length} members'),
                ],
              ),
              const SizedBox(height: 12),
              Text(project.description, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: project.tasks.isEmpty ? 0 : done / project.tasks.length,
                minHeight: 7,
                borderRadius: BorderRadius.circular(99),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Create a project to start collaborating.'));
  }
}
