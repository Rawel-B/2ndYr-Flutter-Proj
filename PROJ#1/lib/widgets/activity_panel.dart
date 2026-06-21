import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/project.dart';
import '../providers/project_provider.dart';

class ActivityPanel extends StatelessWidget {
  const ActivityPanel({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProjectProvider>();
    final activity = provider.activityFor(project.id);
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D121B),
        border: Border(left: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text('Activity', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final item in activity)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bolt_outlined),
              title: Text(provider.userById(item.actorId)?.name ?? 'Unknown'),
              subtitle: Text(item.message),
              trailing: Text(DateFormat.Hm().format(item.createdAt)),
            ),
        ],
      ),
    );
  }
}
