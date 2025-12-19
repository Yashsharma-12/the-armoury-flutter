import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http; 
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Added for Logout
import 'dart:io';
import '../settings_page.dart';
import 'login_page.dart'; // ✅ Ensure this path matches your login page file

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final Color arsenalRed = const Color(0xFFEF0107);
  final String backendUrl = 'https://the-armoury-api.onrender.com/api/user/profile'; 

  String _displayName = "Gooner Since 2004";
  String _email = "arsenalfan@email.com";
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _displayName = prefs.getString('display_name') ?? "Gooner Since 2004";
      _email = prefs.getString('user_email') ?? "arsenalfan@email.com";
      String? imagePath = prefs.getString('profile_pic');
      if (imagePath != null) _imageFile = File(imagePath);
    });
  }

  Future<void> _syncProfileToBackend() async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(backendUrl));
      request.fields['uid'] = "device_user_123"; 
      request.fields['displayName'] = _displayName;
      request.fields['email'] = _email;

      if (_imageFile != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image', 
          _imageFile!.path,
        ));
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        debugPrint("✅ Profile synced to MongoDB successfully");
      } else {
        debugPrint("❌ Backend Sync Failed: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error syncing to backend: $e");
    }
  }

  Future<void> _pickImage() async {
    PermissionStatus status = Platform.isAndroid && (await _getAndroidVersion()) >= 13
        ? await Permission.photos.request()
        : await Permission.storage.request();

    if (status.isGranted) {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, 
      );

      if (pickedFile != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_pic', pickedFile.path);
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        await _syncProfileToBackend(); 
      }
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  Future<int> _getAndroidVersion() async {
    if (Platform.isAndroid) {
      return int.parse(Platform.version.split(' ')[0].split('.')[0]);
    }
    return 0;
  }

  Future<void> _showEditDialog() async {
    TextEditingController controller = TextEditingController(text: _displayName);
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile Name", style: TextStyle(fontFamily: 'ClearfaceGothic')),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Enter new name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: arsenalRed),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('display_name', controller.text);
              setState(() => _displayName = controller.text);
              Navigator.pop(context);
              await _syncProfileToBackend(); 
            },
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'ClearfaceGothic')),
        backgroundColor: arsenalRed,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: arsenalRed, width: 3)),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _imageFile != null 
                          ? FileImage(_imageFile!) as ImageProvider
                          : const NetworkImage('https://img.freepik.com/premium-vector/man-avatar-profile-picture-vector-illustration_268834-538.jpg'),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? const Color(0xFF121212) : Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5)],
                        ),
                        child: Icon(Icons.camera_alt, color: arsenalRed, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(_displayName,
                style: TextStyle(color: textColor, fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'ClearfaceGothic')),
            const SizedBox(height: 5),
            Text(_email, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 30),
            _buildSectionHeader("Account"),
            _buildProfileOption(context, Icons.person, "Edit Profile", _showEditDialog),
            _buildProfileOption(context, Icons.notifications, "Notifications", () {}),
            _buildProfileOption(context, Icons.privacy_tip, "Privacy", () {}),
            _buildSectionHeader("Support"),
            _buildProfileOption(context, Icons.help_outline, "Help & Support", () {}),
            _buildProfileOption(context, Icons.settings, 'Settings', () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage()));
            }),
            const SizedBox(height: 30),
            
            // ✅ UPDATED LOGOUT BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: ElevatedButton(
                onPressed: () async {
                  // 1. Sign out from Firebase
                  await FirebaseAuth.instance.signOut();

                  // 2. Clear local session data
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('is_logged_in', false); 

                  // 3. Navigate to Login and remove history
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: arsenalRed.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: arsenalRed, width: 1.5),
                  ),
                ),
                child: Center(
                  child: Text("Log Out",
                      style: TextStyle(color: arsenalRed, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title.toUpperCase(),
            style: TextStyle(color: arsenalRed, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      ),
    );
  }

  Widget _buildProfileOption(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconBgColor = isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100];
    final textColor = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 2),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: arsenalRed, size: 22),
        ),
        title: Text(title, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
      ),
    );
  }
}