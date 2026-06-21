import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_trello/services/demo_repository.dart';

void main() {
  test('notifications stay private unless the user is admin', () async {
    final repository = DemoRepository(firebaseReady: false);

    final maya = await repository.signIn('maya@fluttertrello.dev', 'password');
    repository.createProject(
      owner: maya,
      name: 'Private rollout',
      description: 'Keep this notification scoped to Maya.',
    );

    final rawel = await repository.signIn('rawel@example.com', 'password');
    final admin = await repository.signIn(DemoRepository.adminEmail, 'password');

    expect(
      repository.notificationsFor(maya).map((item) => item.title),
      contains('Project created'),
    );
    expect(
      repository.notificationsFor(rawel).map((item) => item.title),
      isNot(contains('Project created')),
    );
    expect(
      repository.notificationsFor(admin).map((item) => item.title),
      contains('Project created'),
    );
  });

  test('invite and task notifications go only to relevant users', () async {
    final repository = DemoRepository(firebaseReady: false);

    final admin = await repository.signIn(DemoRepository.adminEmail, 'password');
    final maya = await repository.signIn('maya@fluttertrello.dev', 'password');
    final project = repository.projectsFor(maya).first;

    repository.inviteMember(project, 'rawel@example.com', admin);
    final rawel = await repository.signIn('rawel@example.com', 'password');
    final freshProject = repository.projectById(project.id)!;
    repository.createTask(
      project: freshProject,
      actor: maya,
      title: 'Prepare release notes',
      description: 'Summarize the current sprint.',
      status: freshProject.tasks.first.status,
      assigneeId: rawel.id,
    );

    final rawelTitles = repository.notificationsFor(rawel).map((item) => item.title);
    final mayaTitles = repository.notificationsFor(maya).map((item) => item.title);
    final adminTitles = repository.notificationsFor(admin).map((item) => item.title);

    expect(rawelTitles, contains('You were added to a project'));
    expect(rawelTitles, contains('New task assigned'));
    expect(mayaTitles, isNot(contains('New task assigned')));
    expect(adminTitles, contains('New task assigned'));
  });
}
