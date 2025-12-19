import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final String apiKey = "2ea9d9d1d87642518ad04dbe96346339";
  final String arsenalId = "57";
  final Color arsenalRed = const Color(0xFFEF0107);

  List<dynamic> allMatches = [];
  List<dynamic> filteredMatches = [];
  List<String> months = [];
  String selectedMonth = "All";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllMatches();
  }

  Future<void> fetchAllMatches() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.football-data.org/v4/teams/$arsenalId/matches'),
        headers: {'X-Auth-Token': apiKey},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final matchesList = data['matches'] as List;

        Set<String> monthSet = {"All"};
        for (var m in matchesList) {
          String mName = DateFormat('MMMM').format(DateTime.parse(m['utcDate']));
          monthSet.add(mName);
        }

        if (mounted) {
          setState(() {
            allMatches = matchesList;
            filteredMatches = matchesList;
            months = monthSet.toList();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _filterByMonth(String month) {
    setState(() {
      selectedMonth = month;
      if (month == "All") {
        filteredMatches = allMatches;
      } else {
        filteredMatches = allMatches.where((m) {
          String mName = DateFormat('MMMM').format(DateTime.parse(m['utcDate']));
          return mName == month;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Season Schedule", 
          style: TextStyle(fontFamily: 'ClearfaceGothic', fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: arsenalRed,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: arsenalRed))
          : Column(
              children: [
                // Month Filter Horizontal Bar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(), // ✅ Added Bounce
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: months.length,
                    itemBuilder: (context, index) {
                      bool isSelected = selectedMonth == months[index];
                      return GestureDetector(
                        onTap: () => _filterByMonth(months[index]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: isSelected ? arsenalRed : (isDark ? Colors.grey[900] : Colors.grey[300]),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            months[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                Expanded(
                  child: filteredMatches.isEmpty
                      ? Center(child: Text("No matches found", style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)))
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), // ✅ Added Bounce
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredMatches.length,
                          itemBuilder: (context, index) {
                            final match = filteredMatches[index];
                            final date = DateTime.parse(match['utcDate']).toLocal();
                            
                            // ✅ Wrapping card in an animation for premium feel
                            return TweenAnimationBuilder(
                              duration: Duration(milliseconds: 400 + (index * 50).clamp(0, 400)),
                              tween: Tween<double>(begin: 0.8, end: 1.0),
                              curve: Curves.easeOutBack,
                              builder: (context, double value, child) => Transform.scale(scale: value, child: child),
                              child: Card(
                                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: isDark ? 0 : 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: arsenalRed.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          match['competition']['name'].toUpperCase(),
                                          style: TextStyle(color: arsenalRed, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        children: [
                                          _teamInfo(context, match['homeTeam']['name'], match['homeTeam']['crest']),
                                          _matchStatus(context, match),
                                          _teamInfo(context, match['awayTeam']['name'], match['awayTeam']['crest']),
                                        ],
                                      ),
                                      Divider(color: isDark ? Colors.white10 : Colors.black12, height: 30),
                                      Text(
                                        DateFormat('EEE, d MMM yyyy • HH:mm').format(date),
                                        style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _teamInfo(BuildContext context, String name, String? crest) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Column(
        children: [
          crest != null && !crest.endsWith('.svg')
              ? Image.network(crest, height: 40, width: 40)
              : Icon(Icons.shield, color: isDark ? Colors.white24 : Colors.black12, size: 40),
          const SizedBox(height: 8),
          Text(
            name.replaceAll("Arsenal FC", "Arsenal"),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyLarge?.color, 
              fontWeight: FontWeight.bold, 
              fontSize: 12
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _matchStatus(BuildContext context, dynamic match) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (match['status'] == 'FINISHED') {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          "${match['score']['fullTime']['home']} - ${match['score']['fullTime']['away']}",
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color, 
            fontSize: 20, 
            fontWeight: FontWeight.bold
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text("VS", 
        style: TextStyle(
          color: isDark ? Colors.grey : Colors.grey[600], 
          fontWeight: FontWeight.bold
        )
      ),
    );
  }
}