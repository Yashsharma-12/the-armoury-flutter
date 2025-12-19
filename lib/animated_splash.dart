import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ✅ These imports are back so we can use the class names directly
import 'pages/home.dart';
import 'login_page.dart';

class AnimatedSplash extends StatefulWidget {
  const AnimatedSplash({super.key});

  @override
  State<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<AnimatedSplash> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // 1. Setup Fade-in Animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.forward();

    // 2. Start navigation logic
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    // Show splash for 3 seconds total
    await Future.delayed(const Duration(seconds: 3));
    
    // Remove the native splash layer
    FlutterNativeSplash.remove();

    final prefs = await SharedPreferences.getInstance();
    final String? userUid = prefs.getString('user_uid');

    if (mounted) {
      if (userUid != null) {
        // ✅ Direct Navigation to MyWidget (Home)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyWidget()),
        );
      } else {
        // ✅ Direct Navigation to LoginPage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // ✅ Pure Black Background
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Your New Logo
              Image.asset(
                'assets/images/splash_logo.jpeg',
                width: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.shield,
                  color: Color(0xFFEF0107),
                  size: 100,
                ),
              ),
              const SizedBox(height: 24),
              // App Name in White
              const Text(
                "THE ARMOURY",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}