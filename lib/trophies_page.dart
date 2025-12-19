import 'package:flutter/material.dart';

class TrophiesPage extends StatelessWidget {
  const TrophiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Trophy Room", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFEF0107),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        children: [
          _buildTrophyCard("League Titles", "13", Icons.emoji_events),
          _buildTrophyCard("FA Cups", "14", Icons.workspace_premium),
          _buildTrophyCard("League Cups", "2", Icons.military_tech),
          _buildTrophyCard("Community Shields", "17", Icons.shield),
        ],
      ),
    );
  }

  Widget _buildTrophyCard(String name, String count, IconData icon) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.amber, size: 50),
          const SizedBox(height: 10),
          Text(count, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          Text(name, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }
}