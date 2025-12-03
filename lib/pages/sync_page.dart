import 'package:flutter/material.dart';

class SyncStatusPage extends StatelessWidget {
  const SyncStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Status'),
        backgroundColor: Colors.blue[900],
      ),
      body: const Center(child: Text('Sync Status Page Content')),
    );
  }
}
