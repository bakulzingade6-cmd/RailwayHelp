import 'package:flutter/material.dart';

class DepotReceiptPage extends StatelessWidget {
  const DepotReceiptPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Depot Receipt'),
        backgroundColor: Colors.blue[900],
      ),
      body: const Center(
        child: Text('Depot Receipt Page Content'),
      ),
    );
  }
}
