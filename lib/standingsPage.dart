import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StandingsPage extends StatefulWidget {
  final int initialIndex; 

  const StandingsPage({super.key, required this.initialIndex});

  @override
  State<StandingsPage> createState() => _StandingsPageState();
}

class _StandingsPageState extends State<StandingsPage> {
  late PageController _pageController;
  late int _currentIndex;
  
  // Official Arsenal Red
  final Color arsenalRed = const Color(0xFFEF0107);

  final List<Map<String, String>> leagues = [
    {'id': 'PL', 'name': 'Premier League'},
    {'id': 'CL', 'name': 'Champions League'},
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Standings",
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: Colors.white, 
            fontFamily: 'ClearfaceGothic'
          ),
        ),
        backgroundColor: arsenalRed, // Updated color
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: arsenalRed, // Updated color
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3), 
                  blurRadius: 10, 
                  offset: const Offset(0, 5)
                )
              ],
            ),
            child: Text(
              leagues[_currentIndex]['name']!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 22, 
                fontWeight: FontWeight.bold
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: leagues.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                return StandingsList(
                  key: PageStorageKey(leagues[index]['id']), 
                  leagueId: leagues[index]['id']!
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StandingsList extends StatefulWidget {
  final String leagueId;
  const StandingsList({super.key, required this.leagueId});

  @override
  State<StandingsList> createState() => _StandingsListState();
}

class _StandingsListState extends State<StandingsList> {
  final String apiKey = "2ea9d9d1d87642518ad04dbe96346339";
  late Future<List<dynamic>> _standingsFuture;
  final Color arsenalRed = const Color(0xFFEF0107);

  @override
  void initState() {
    super.initState();
    _standingsFuture = fetchStandings();
  }

  Future<List<dynamic>> fetchStandings() async {
    final url = 'https://api.football-data.org/v4/competitions/${widget.leagueId}/standings';
    try {
      final response = await http.get(Uri.parse(url), headers: {'X-Auth-Token': apiKey});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['standings'][0]['table'];
      } else {
        throw Exception('Failed to load standings');
      }
    } catch (e) {
      throw Exception('Error fetching data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          color: const Color(0xFF1E1E1E),
          child: const Row(
            children: [
              SizedBox(width: 30, child: Text("Pos", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              Expanded(child: Text("Club", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              SizedBox(width: 30, child: Text("Pl", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              SizedBox(width: 30, child: Text("GD", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
              SizedBox(width: 30, child: Text("Pts", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _standingsFuture, 
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: arsenalRed));
              } else if (snapshot.hasError) {
                return const Center(child: Text("Error loading table", style: TextStyle(color: Colors.grey)));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No data available", style: TextStyle(color: Colors.grey)));
              }

              final table = snapshot.data!;

              return ListView.separated(
                itemCount: table.length,
                separatorBuilder: (c, i) => const Divider(color: Colors.grey, height: 1),
                itemBuilder: (context, index) {
                  final teamData = table[index];
                  final team = teamData['team'];
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  final textColor = isDark ? Colors.white : Colors.black;

                  // Highlighting Arsenal
                  bool isArsenal = team['name'] == "Arsenal FC";

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    color: isArsenal ? arsenalRed.withOpacity(0.1) : Colors.transparent,
                    child: Row(
                      children: [
                        SizedBox(width: 30, child: Text("${teamData['position']}", 
                          style: TextStyle(color: isArsenal ? arsenalRed : textColor, fontWeight: FontWeight.bold))),
                        Expanded(
                          child: Row(
                            children: [
                              Image.network(team['crest'], height: 24, width: 24, 
                                errorBuilder: (c,o,s) => Icon(Icons.shield, color: textColor, size: 20)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  team['shortName'] ?? team['name'],
                                  style: TextStyle(
                                    color: isArsenal ? arsenalRed : textColor,
                                    fontWeight: isArsenal ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 30, child: Text("${teamData['playedGames']}", style: const TextStyle(color: Colors.grey))),
                        SizedBox(width: 30, child: Text("${teamData['goalDifference']}", style: const TextStyle(color: Colors.grey))),
                        SizedBox(width: 30, child: Text("${teamData['points']}", 
                          style: TextStyle(color: isArsenal ? arsenalRed : textColor, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}