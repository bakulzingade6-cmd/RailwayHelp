// import files (adjust paths)
import 'package:flutter/material.dart';
import 'package:majdur_p/pages/Installation/installation_DB.dart';
import 'common_scanner.dart';


class Name_of_scanner extends StatelessWidget {
  const Name_of_scanner ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan (direct)')),
      body: Center(
        child: ElevatedButton(
          child: const Text('Open Scanner'),
          onPressed: () async {
            final String? scanned = await Navigator.push<String?>(
              context,
              MaterialPageRoute(
                builder: (_) => const CommonScannerPage(
                  title: 'Scan Receipt QR',
                  allowPaste: true,
                ),
              ),
            );

            if (scanned != null && scanned.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => InstallationDb(rawJson: scanned)),// name of the db page
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scan cancelled')),
              );
            }
          },
        ),
      ),
    );
  }
}
