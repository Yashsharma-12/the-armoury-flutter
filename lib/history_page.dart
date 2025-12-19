import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Club History", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFEF0107),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHistorySection("Founding (1886)", "Dial Square was formed by workers at the Royal Arsenal in Woolwich. Later renamed to Royal Arsenal, then Woolwich Arsenal."),
          _buildHistorySection("The Chapman Era (1925-1934)", "Herbert Chapman revolutionized the club, introducing the WM formation and leading us to our first major trophies."),
          _buildHistorySection("Move to Highbury (1913)", "The club moved to North London, establishing a legendary home that lasted for 93 years."),
          _buildHistorySection("Modern Era & Emirates (2006)", "The transition to the state-of-the-art Emirates Stadium marked a new chapter in global football."),
        ],
      ),
    );
  }

  Widget _buildHistorySection(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFFEF0107), fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5)),
        ],
      ),
    );
  }
}