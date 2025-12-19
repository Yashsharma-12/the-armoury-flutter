import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final Color arsenalRed = const Color(0xFFEF0107);
  bool _isLoading = false;

  Future<void> _register() async {
    // 1. Validation
    if (_nameController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty || 
        _passwordController.text.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // 2. API Call
      final response = await http.post(
        Uri.parse('https://the-armoury-api.onrender.com/api/auth/register'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "displayName": _nameController.text.trim(),
          "email": _emailController.text.trim().toLowerCase(),
          "password": _passwordController.text,
          "uid": DateTime.now().millisecondsSinceEpoch.toString(), 
        }),
      ).timeout(const Duration(seconds: 30));

      // 3. Handle Response
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account Created Successfully! Please Login."), 
              backgroundColor: Colors.green
            ),
          );
          // Navigate to Login
          Navigator.pushAndRemoveUntil(
            context, 
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false
          );
        }
      } else {
        _showError(data['error'] ?? "Registration Failed");
      }
    } on TimeoutException catch (_) {
      _showError("Server is taking too long to respond. Try again.");
    } catch (e) {
      debugPrint("Register Error: $e");
      _showError("Could not connect to server. Check your internet.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add, color: Color(0xFFEF0107), size: 70),
                const SizedBox(height: 20),
                const Text("JOIN THE ARMOURY",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'ClearfaceGothic')),
                const SizedBox(height: 10),
                const Text("Create an account to sync your profile",
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 40),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Full Name", Icons.person),
                ),
                const SizedBox(height: 15),
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
                    ? const CircularProgressIndicator(color: Color(0xFFEF0107))
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: arsenalRed,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        onPressed: _register,
                        child: const Text("Create Account",
                            style: TextStyle(color: Colors.white, fontSize: 18)),
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
          borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: arsenalRed),
          borderRadius: BorderRadius.circular(10)),
    );
  }
}