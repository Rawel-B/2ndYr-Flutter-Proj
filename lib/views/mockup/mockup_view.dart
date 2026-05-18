import 'package:flutter/material.dart';

class MockupView extends StatelessWidget {
  const MockupView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visual mockup')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'FlutterTrello interface plan',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use this screen as the required visual maquette reference. It maps the app navigation, dashboard, board columns, task cards, activity, and admin metrics.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          const _MockupFrame(),
        ],
      ),
    );
  }
}

class _MockupFrame extends StatelessWidget {
  const _MockupFrame();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1018),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF243044)),
        ),
        child: Row(
          children: [
            Container(
              width: 190,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Projects', style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  for (final label in ['Mobile Launch', 'Client Portal', 'QA Sprint'])
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2332),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Mobile Launch Board',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                      ),
                      Icon(Icons.notifications_outlined),
                      SizedBox(width: 12),
                      Icon(Icons.person_add_alt),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Row(
                      children: [
                        for (final column in ['To do', 'In progress', 'Done'])
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF101722),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(column, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 10),
                                  for (var index = 0; index < 3; index++)
                                    Container(
                                      height: 58,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF182234),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
