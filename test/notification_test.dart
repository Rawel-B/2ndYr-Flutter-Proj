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
}
