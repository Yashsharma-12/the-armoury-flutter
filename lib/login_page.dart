import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/home.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Color arsenalRed = const Color(0xFFEF0107);
  bool _isLoading = false;

  // ✅ New Guest Login Logic
  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_guest', true);
      await prefs.setBool('is_logged_in', true); // Ensures app stays open
      await prefs.setString('display_name', "Guest Gooner");
      await prefs.setString('user_uid', "guest_user");

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyWidget()),
        );
      }
    } catch (e) {
      _showError("Error entering as guest");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError("Fields cannot be empty");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('https://the-armoury-api.onrender.com/api/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text.trim().toLowerCase(),
          "password": _passwordController.text,
        }),
      ).timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_uid', data['uid']);
        await prefs.setString('display_name', data['displayName']);
        await prefs.setBool('is_guest', false);
        await prefs.setBool('is_logged_in', true);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MyWidget()),
          );
        }
      } else {
        _showError(data['error'] ?? "Login Failed");
      }
    } catch (e) {
      _showError("Could not connect to server.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/icons/splash_logo.jpeg',
                    height: 120,
                    width: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.shield, color: arsenalRed, size: 80);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "THE ARMOURY",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Email", Icons.email),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Password", Icons.lock),
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? CircularProgressIndicator(color: arsenalRed)
                    : Column(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: arsenalRed,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _login,
                            child: const Text(
                              "Login",
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ),
                          const SizedBox(height: 15),
                          // ✅ New Guest Button
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              side: BorderSide(color: arsenalRed),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _continueAsGuest,
                            child: Text(
                              "Continue as Guest",
                              style: TextStyle(color: arsenalRed, fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterPage()),
                            ),
                            child: Text(
                              "New here? Create an Account",
                              style: TextStyle(
                                color: arsenalRed,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: Colors.grey),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: arsenalRed),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}