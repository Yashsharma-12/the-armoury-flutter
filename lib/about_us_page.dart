import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("About Us", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFEF0107),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Padding(
        padding: EdgeInsets.all(25.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Arsenal Fan App", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("Version 1.0.25 (2025/26 Season)", style: TextStyle(color: Colors.grey)),
              SizedBox(height: 30),
              Text(
                "Built for Gooners worldwide. Get live lineups, track standings, and explore the rich history of the greatest club in London.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}