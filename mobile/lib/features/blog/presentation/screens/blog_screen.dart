import 'package:flutter/material.dart';

class _Post {
  const _Post(this.title, this.body);
  final String title;
  final String body;
}

const _posts = [
  _Post(
    'Why Discipline Builds Champions',
    'Every round in the ring starts long before the bell. The habits young athletes build at Junior Boy Boxing — showing up on time, listening to coaching, pushing through a hard set — carry over into school, friendships and family life. Boxing teaches that progress comes from consistency, not shortcuts.',
  ),
  _Post(
    'Getting Started: What To Expect In Your First Class',
    'New to boxing? Your first session focuses on the fundamentals: stance, footwork and basic combinations. Coach Sharif keeps class sizes small so every athlete gets personal attention. Wear comfortable athletic clothes, bring water, and come ready to learn — gloves and wraps are provided for beginners.',
  ),
  _Post(
    'Confidence Beyond The Gym',
    'Parents often tell us the biggest change they see isn\'t physical — it\'s how their child carries themselves afterward. Boxing builds self-control and focus under pressure, skills that help on test day as much as on fight day.',
  ),
];

class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Blog')),
    body: ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: _posts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 28),
      itemBuilder: (context, index) {
        final post = _posts[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            Text(post.body, style: const TextStyle(height: 1.6)),
          ],
        );
      },
    ),
  );
}
