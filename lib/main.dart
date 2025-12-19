import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart'; 

// Page Imports
import 'pages/home.dart';
import 'login_page.dart'; 
import 'register_page.dart'; 
import 'theme_notifier.dart'; 
import 'animated_splash.dart';

// ✅ 1. Background Message Handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

void main() async {
  // ✅ 2. Initialize Flutter Bindings
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ 3. Preserve Native Splash
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // ✅ 4. Initialize Theme Settings from Storage
  await ThemeService.init();

  // ✅ 5. Initialize Firebase
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }

  // ✅ 6. Check Login Session
  final prefs = await SharedPreferences.getInstance();
  final String? userUid = prefs.getString('user_uid');

  runApp(MyApp(isLoggedIn: userUid != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn; 

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'The Armoury',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode, 

          // --- LIGHT THEME ---
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF5F5F5), 
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFEF0107), 
              brightness: Brightness.light,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFEF0107),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            // ✅ FIXED: Using CardThemeData instead of CardTheme
            cardTheme: const CardThemeData(
              color: Colors.white,
              elevation: 2,
              margin: EdgeInsets.all(8),
            ),
          ),

          // --- DARK THEME ---
          darkTheme: ThemeData( 
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212), 
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFEF0107), 
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFEF0107),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            // ✅ FIXED: Using CardThemeData instead of CardTheme
            cardTheme: const CardThemeData(
              color: Color(0xFF1E1E1E),
              elevation: 2,
              margin: EdgeInsets.all(8),
            ),
          ),
          
          initialRoute: '/',
          routes: {
            '/': (context) => const AnimatedSplash(), 
            '/login': (context) => const LoginPage(),
            '/register': (context) => const RegisterPage(),
            '/home': (context) => const MyWidget(),
          },
        );
      },
    );
  }
}