// lib/pages/homepage.dart
import 'package:flutter/material.dart';
import 'package:majdur_p/auth/loginpage.dart';
import 'package:majdur_p/pages/cv_detect.dart';
import 'package:majdur_p/pages/file_receipt/receipt_scanner.dart';
import 'package:majdur_p/pages/Installation/install_scanner.dart';
import 'package:majdur_p/pages/history_page.dart';
import 'package:majdur_p/pages/inspection/inspect_page.dart';
import 'package:majdur_p/pages/remove/depot_receipt.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int _activeBottomIndex = 0;

  final List<_MenuItem> _menuItems = [
    _MenuItem(icon: Icons.file_download, label: "FILE RECEIPT", colorStart: Colors.blue.shade600, colorEnd: Colors.blue.shade800, target: ScanDirectPage()),
    _MenuItem(icon: Icons.build, label: "Install", colorStart: Colors.blue.shade700, colorEnd: Colors.blue.shade900, target: InstallScannerPage()),
    _MenuItem(icon: Icons.search, label: "Inspect", colorStart: Colors.indigo.shade600, colorEnd: Colors.blue.shade700, target: InspectionScanner()),
    _MenuItem(icon: Icons.receipt, label: "Part Removal", colorStart: Colors.indigo.shade500, colorEnd: Colors.blue.shade600, target: const PartRemovalScanner()),
    _MenuItem(icon: Icons.history, label: "History", colorStart: Colors.blue.shade700, colorEnd: Colors.blue.shade900, target: HistoryPage()),
    _MenuItem(icon: Icons.camera_outdoor, label: "CV Classification", colorStart: Colors.blue.shade400, colorEnd: Colors.blue.shade600, target: YoloImage11()),
  ];

  // sample recent activity items (you can replace with actual data)
  final List<_Activity> _recent = const [
    _Activity(action: "File Receipt submitted", time: "2 hours ago", icon: Icons.file_download),
    _Activity(action: "Part inspection completed", time: "5 hours ago", icon: Icons.search),
    _Activity(action: "Installation verified", time: "1 day ago", icon: Icons.build),
  ];

  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  void _onTilePressed(_MenuItem item) {
    // basic toast-like feedback using SnackBar
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening ${item.label}...'), duration: const Duration(milliseconds: 700)));

    // navigate if target provided
    if (item.target != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => item.target!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Colors.blue[900]!;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Railway Dashboard', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
        centerTitle: true,
        elevation: 6,
        backgroundColor: primary,
        actions: [
          // notifications button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new notifications')));
                  },
                ),
                // red dot
                Positioned(top: 10, right: 10, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              // user info card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [primary.withOpacity(0.95), primary.withOpacity(0.75)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: primary.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 6))],
                      ),
                      child: const Center(child: Icon(Icons.person, color: Colors.white, size: 28)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Welcome back!', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('employee@railway.gov.in', style: TextStyle(color: Colors.black54, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                      child: const Text('Active', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 12)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // quick actions panel
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: _menuItems.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.0,
                              ),
                              itemBuilder: (context, i) {
                                final item = _menuItems[i];
                                return _DashboardTile(
                                  icon: item.icon,
                                  label: item.label,
                                  colorStart: item.colorStart,
                                  colorEnd: item.colorEnd,
                                  onPressed: () => _onTilePressed(item),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Recent Activity
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 14, offset: const Offset(0, 6))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Recent Activity', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Column(
                              children: _recent.map((act) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: primary.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(act.icon, color: primary, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(act.action, style: const TextStyle(fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 4),
                                            Text(act.time, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // bottom navigation
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(10),
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.98),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(icon: Icons.file_download, label: 'Files', index: 0),
              _buildBottomNavItem(icon: Icons.search, label: 'Search', index: 1),
              _buildBottomNavItem(icon: Icons.history, label: 'History', index: 2),
              _buildBottomNavItem(icon: Icons.person, label: 'Profile', index: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({required IconData icon, required String label, required int index}) {
    final bool active = index == _activeBottomIndex;
    final primary = Colors.blue[900]!;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() => _activeBottomIndex = index);
        // route or action based on index if needed
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: active ? Colors.white : Colors.black54),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: active ? Colors.white : Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color colorStart;
  final Color colorEnd;
  final VoidCallback onPressed;

  const _DashboardTile({
    super.key,
    required this.icon,
    required this.label,
    required this.colorStart,
    required this.colorEnd,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [colorStart, colorEnd], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: colorStart.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 8))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white24,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                  ),
                  child: Icon(icon, size: 28, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color colorStart;
  final Color colorEnd;
  final Widget? target;
  _MenuItem({required this.icon, required this.label, required this.colorStart, required this.colorEnd, this.target});
}

class _Activity {
  final String action;
  final String time;
  final IconData icon;
  const _Activity({required this.action, required this.time, required this.icon});
}

