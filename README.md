🔴⚪ The Armoury – The Ultimate Arsenal Fan Companion
The Armoury is a high-performance, feature-rich mobile application designed specifically for Arsenal supporters. Built with Flutter and powered by a Node.js/MongoDB backend, it provides fans with real-time squad insights, matchday lineups, and a personalized profile experience.

🚀 Key Features
Live Matchday Pitch: A dynamic, visual representation of the Arsenal starting XI. The app intelligently fetches the current lineup from the API or defaults to the "Best XI" fallback.

Player Database: Explore the full squad with detailed stats, player roles (GK, DEF, MID, FWD), and official squad numbers.

Secure Authentication: Full user registration and login system integrated with Firebase Auth and a custom MongoDB backend.

Guest Mode: Allows fans to explore the app instantly without creating an account.

Personalized Profiles: Users can set display names and upload custom profile pictures that sync across their local device and the cloud.

Matchday Settings: Admin-ready architecture that allows for real-time updates to the starting lineup and substitute bench.

🛠️ Technical Stack
Frontend: Flutter (Dart) with SharedPreferences for local session persistence.

Backend: Node.js & Express.js hosted on Render.

Database: MongoDB Atlas for player data and user profiles.

Authentication: Firebase Authentication for secure handshakes.

Storage: Multi-part image handling with Multer for profile management.

📥 Installation & Build
This repository contains the full source code for the Flutter application. To generate your own APK:

Ensure you have the google-services.json in the android/app/ folder.

Run flutter pub get.

Run flutter build apk --release.
