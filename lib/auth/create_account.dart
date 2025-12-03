import 'package:flutter/material.dart';
import 'package:majdur_p/auth/loginpage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[900],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),
                ClipOval(
                  child: Image.asset(
                    'assets/railway_logo.png',
                    height: 140,
                    width: 140,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Official Email',
                    prefixIcon: Icon(Icons.email, color: Colors.blue),
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter email' : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Create Password',
                    prefixIcon: Icon(Icons.lock, color: Colors.blue),
                  ),
                  validator: (value) => value!.isEmpty ? 'Enter password' : null,
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[900],
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _createAccount,
                    child: const Text(
                      'REGISTER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Back to Login',
                    style: TextStyle(color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (response.user != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created! Please login.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account creation failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
