import 'package:flutter/material.dart';
import 'package:majdur_p/auth/loginpage.dart';
import 'package:majdur_p/pages/file_receipt/receipt_scanner.dart';
import 'package:majdur_p/pages/Installation/install_scanner.dart';
import 'package:majdur_p/pages/remove/depot_receipt.dart';
import 'package:majdur_p/pages/history_page.dart';
import 'package:majdur_p/pages/inspection/inspect_page.dart';
import 'package:majdur_p/pages/sync_page.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryDarkBlue = Colors.blue[900]!;
    final Color secondaryBlue = Colors.blue[700]!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Railway Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        centerTitle: true,
        elevation: 6,
        backgroundColor: primaryDarkBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        shadowColor: Colors.black45,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);

              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              }
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          childAspectRatio: 0.95,
          children: [
            _buildDashboardTile(
              icon: Icons.file_download,
              label: 'FILE RECEIPT',
              backgroundColor: secondaryBlue,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanDirectPage()),
              ),
            ),
            _buildDashboardTile(
              icon: Icons.build,
              label: 'Install',
              backgroundColor: secondaryBlue,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => InstallScannerPage()),
              ),
            ),
            _buildDashboardTile(
              icon: Icons.search,
              label: 'Inspect',
              backgroundColor: secondaryBlue,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) =>  InspectionScanner()),
              ),
            ),
            _buildDashboardTile(
              icon: Icons.receipt,
              label: 'Part Removal',
              backgroundColor: secondaryBlue,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PartRemovalScanner()),
              ),
            ),
            _buildDashboardTile(
              icon: Icons.history,
              label: 'History',
              backgroundColor: secondaryBlue,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => HistoryPage()),
              ),
            ),
            _buildDashboardTile(
              icon: Icons.sync,
              label: 'Sync Status',
              backgroundColor: secondaryBlue,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SyncStatusPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTile({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            backgroundColor.withOpacity(0.95),
            backgroundColor.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.45),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          splashColor: Colors.white.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 26.0, horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 52, color: Colors.white),
                const SizedBox(height: 14),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.black26,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
