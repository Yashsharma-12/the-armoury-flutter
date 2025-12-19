import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PlayerInfoPage extends StatefulWidget {
  final dynamic player;
  const PlayerInfoPage({super.key, required this.player});

  @override
  State<PlayerInfoPage> createState() => _PlayerInfoPageState();
}

class _PlayerInfoPageState extends State<PlayerInfoPage> {
  String selectedCategory = "Attack";
  bool isLoading = true;
  Map<String, dynamic>? playerStats;

  @override
  void initState() {
    super.initState();
    fetchStatsFromBackend();
  }

Future<void> fetchStatsFromBackend() async {
  final String baseUrl = 'https://the-armoury-api.onrender.com/api/squad';

  try {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      final List<dynamic> squad = json.decode(response.body);
      
      // 1. Get the name we are looking for from the widget
      String targetName = widget.player['name'].toString().toLowerCase().trim();

      // 2. Find the player using a flexible comparison
      final foundPlayer = squad.firstWhere(
        (p) => p['name'].toString().toLowerCase().trim() == targetName,
        orElse: () => null,
      );

      if (mounted) {
        setState(() {
          // 3. Specifically check if 'stats' exists inside the found player
          if (foundPlayer != null && foundPlayer.containsKey('stats')) {
            playerStats = foundPlayer['stats'];
          } else {
            playerStats = null;
            debugPrint("Match found for $targetName, but 'stats' object is missing.");
          }
          isLoading = false;
        });
      }
    }
  } catch (e) {
    debugPrint("Backend Connection Error: $e");
    if (mounted) setState(() => isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 30),
            _buildTabSelector(),
            const SizedBox(height: 30),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: _buildSelectedStats(),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedStats() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(color: Colors.redAccent),
        ),
      );
    }

    if (playerStats == null) {
      return const Center(
        child: Text("No stats found for this player in your database."),
      );
    }

    final attack = playerStats!['attack'] ?? {};
    final defence = playerStats!['defence'] ?? {};
    final discipline = playerStats!['discipline'] ?? {};

    if (selectedCategory == "Defence") {
      double tackleRate = _calculateRate(defence['tackles'], defence['tacklesAttempted']);
      double duelRate = _calculateRate(defence['duels'], defence['duelsAttempted']);

      return Column(
        children: [
          Row(
            children: [
              _simpleStat("${defence['clearances'] ?? 0}", "Clearances"),
              _simpleStat("${defence['blocks'] ?? 0}", "Blocks"),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              _circularStat(tackleRate, "${(tackleRate * 100).toStringAsFixed(1)}%", "Tackles"),
              _circularStat(duelRate, "${(duelRate * 100).toStringAsFixed(1)}%", "Duels"),
            ],
          ),
        ],
      );
    } else if (selectedCategory == "Discipline") {
  return Column(
    children: [
      _disciplineRow("${discipline['foulsWon'] ?? 0}", "Fouls won"),
      _divider(),
      _disciplineRow("${discipline['foulsConceded'] ?? 0}", "Fouls conceded"),
      _divider(),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Using Colors.amber[800] for better visibility on white
          _cardBox("${discipline['yellowCards'] ?? 0}", "Yellow", 
              Colors.amber.shade50, Colors.amber.shade900),
          const SizedBox(width: 30),
          // Using a deep red
          _cardBox("${discipline['redCards'] ?? 0}", "Red", 
              Colors.red.shade50, Colors.red.shade900),
        ],
      ),
    ],
  );
    } else {
      return Column(
        children: [
          _buildStatBar("Total shots", (attack['totalShots'] ?? 0).toDouble(), 50),
          _buildStatBar("Shots on target", (attack['shotsOnTarget'] ?? 0).toDouble(), 50),
          _buildStatBar("Goals scored", (attack['goals'] ?? 0).toDouble(), 20),
          const Divider(height: 40),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2,
            children: [
              _gridStat("${attack['assists'] ?? 0}", "Assists"),
              _gridStat("${attack['leftFootGoals'] ?? 0}", "Left Foot"),
              _gridStat("${attack['rightFootGoals'] ?? 0}", "Right Foot"),
              _gridStat("${attack['headedGoals'] ?? 0}", "Headed"),
            ],
          ),
        ],
      );
    }
  }

  // --- UI COMPONENTS & HELPERS (Keep existing) ---

  Widget _buildHeader() {
  // Extracting data from the player object passed from Home
  final String name = widget.player['name'] ?? 'Unknown Player';
  final String number = widget.player['number'] ?? '0';
  final String image = widget.player['image'] ?? '';
  
  // Mapping 'pos' from backend to a full name if desired, or just use pos
  final String position = widget.player['pos'] ?? 'N/A';
  
  // Note: If you haven't added age/country to your MongoDB yet, 
  // these will show 'N/A' until you update your server.js seeder.
  final String age = widget.player['age']?.toString() ?? '24'; 
  final String country = widget.player['country'] ?? 'England';

  return Stack(
    children: [
      Container(
        height: 200,
        decoration: const BoxDecoration(
          color: Color(0xFFEF0107),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
      ),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackButton(color: Colors.white),
              Text(
                name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      color: Colors.white,
                      height: 180,
                      width: 140,
                      child: Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => const Icon(Icons.person, size: 80),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "#$number",
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 36, 
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        "Age: $age", 
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Text(
                        "Country: $country", 
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Text(
                        "Position: $position", 
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _categoryTab("Attack", Icons.change_history),
          _categoryTab("Defence", Icons.security),
          _categoryTab("Discipline", Icons.warning_amber),
        ],
      ),
    );
  }

  Widget _categoryTab(String label, IconData icon) {
    bool isActive = selectedCategory == label;
    return GestureDetector(
      onTap: () { if (mounted) setState(() => selectedCategory = label); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.redAccent, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isActive ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _circularStat(double progress, String percentage, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80, width: 80,
                child: CircularProgressIndicator(
                  value: progress, strokeWidth: 8,
                  backgroundColor: Colors.grey.shade200, color: Colors.red,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(percentage, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const Text("Success", style: TextStyle(fontSize: 8, color: Colors.grey)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _simpleStat(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _disciplineRow(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _cardBox(String value, String label, Color bg, Color borderColor) {
  return Container(
    width: 90,
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      color: bg,
      border: Border.all(color: borderColor, width: 2), // Thicker border for visibility
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: borderColor.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 26, 
            color: borderColor, // Darker color used here
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11, 
            color: borderColor.withOpacity(0.8), // Matches the theme
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

  double _calculateRate(dynamic won, dynamic total) {
    if (total == null || total == 0) return 0.0;
    return (won ?? 0).toDouble() / total.toDouble();
  }

  Widget _divider() => const Divider(height: 1, color: Colors.grey);

  Widget _buildStatBar(String label, double value, double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.black)),
              Text(value.toInt().toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(value: value / total, backgroundColor: Colors.grey[200], color: Colors.red, minHeight: 8),
        ],
      ),
    );
  }

  Widget _gridStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }
}