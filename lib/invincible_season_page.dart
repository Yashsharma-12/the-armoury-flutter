import 'package:flutter/material.dart';

class InvinciblesPage extends StatelessWidget {
  const InvinciblesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          "The Invincibles",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.amber[700], // Golden theme for the gold trophy
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 100),
            const Text(
              "P38 W26 D12 L0",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "In the 2003-04 season, Arsenal achieved the impossible by going the entire Premier League campaign undefeated. Led by Arsene Wenger, the team secured the only Gold Premier League trophy in history.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 30),
            
            // Stats Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "SEASON STATS",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
            ),
            const Divider(color: Colors.grey),
            buildStatRow("Top Scorer", "Thierry Henry (30)"),
            buildStatRow("Most Assists", "Robert Pires (7)"),
            buildStatRow("Clean Sheets", "Jens Lehmann (15)"),
            buildStatRow("Biggest Win", "5-0 vs Leeds United"),
          ],
        ),
      ),
    );
  }

  Widget buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}