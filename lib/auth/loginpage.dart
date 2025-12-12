// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:majdur_p/auth/create_account.dart';
import 'package:majdur_p/pages/homepage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  late final AnimationController _animController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.06).animate(CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // supabase v1/v2 differences: response.user may exist or response.session
      final user = (response as dynamic).user ?? (response as dynamic).session?.user;
      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login successful'), backgroundColor: Colors.green));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
      } else {
        // If response didn't include user, attempt to inspect response.error if present
        final err = (response as dynamic).error;
        final msg = err?.message ?? 'Login failed';
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildBackgroundBlobs() {
    return Stack(
      children: [
        // big centered soft circle
        Positioned.fill(
          child: Center(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (c, w) {
                return Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 600,
                    height: 600,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.04),
                      shape: BoxShape.circle,
                      // soft blur effect achieved by large boxShadow
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.06),
                          blurRadius: 80,
                          spreadRadius: 40,
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // top-right blob
        Positioned(
          top: 40,
          right: -40,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(200),
              boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.12), blurRadius: 40)],
            ),
          ),
        ),

        // bottom-left blob
        Positioned(
          bottom: -40,
          left: -40,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(260),
              boxShadow: [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.08), blurRadius: 50)],
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
      filled: true,
      fillColor: Colors.white.withOpacity(0.6),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.15)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Theme.of(context).primaryColor.withOpacity(0.35), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor; // expects your theme primary to be the railway blue
    return Scaffold(
      // extend body behind appbar so blobs can be seen at the top
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Railway Corporation', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary.withOpacity(0.06),
                  Theme.of(context).colorScheme.background,
                  primary.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // decorative blobs
          _buildBackgroundBlobs(),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Card container (glass effect)
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 520),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 8))
                        ],
                        border: Border.all(color: Colors.white.withOpacity(0.6)),
                      ),
                      child: Column(
                        children: [
                          // logo
                          SizedBox(
                            height: 96,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // soft pulse behind logo
                                AnimatedBuilder(
                                  animation: _pulseAnim,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _pulseAnim.value,
                                      child: Container(
                                        width: 86,
                                        height: 86,
                                        decoration: BoxDecoration(
                                          color: primary.withOpacity(0.22),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: primary.withOpacity(0.18), blurRadius: 30, spreadRadius: 2),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Container(
                                  width: 74,
                                  height: 74,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(colors: [primary, primary.withOpacity(0.85)]),
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: primary.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 6))],
                                  ),
                                  child: const Center(child: Text('🚂', style: TextStyle(fontSize: 28))),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          Text('Employee Login', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: primary)),
                          const SizedBox(height: 6),
                          Text('Enter your credentials to access the dashboard', style: TextStyle(color: Colors.grey[700], fontSize: 13)),

                          const SizedBox(height: 20),

                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                // Email
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _inputDecoration(label: 'Official Email', icon: Icons.mail),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Enter email' : null,
                                ),
                                const SizedBox(height: 14),

                                // Password
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  decoration: _inputDecoration(label: 'Password', icon: Icons.lock),
                                  validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
                                ),

                                const SizedBox(height: 20),

                                // Login button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      backgroundColor: primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      elevation: 8,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              const Text('LOGIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                                              const SizedBox(width: 10),
                                              Transform.translate(
                                                offset: const Offset(0, 0),
                                                child: Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAccountPage()));
                                  },
                                  child: Text('Create New Account', style: TextStyle(color: primary, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    // small footer
                    Text('© Railway Corporation', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
