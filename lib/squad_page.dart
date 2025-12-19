import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'player_profile_page.dart';

class SquadPage extends StatefulWidget {
  const SquadPage({super.key});

  @override
  State<SquadPage> createState() => _SquadPageState();
}

class _SquadPageState extends State<SquadPage> {
  final Color arsenalRed = const Color(0xFFEF0107);
  
  List<dynamic> starters = [];
  List<dynamic> substitutes = [];
  String matchTitle = "Loading Live Lineup...";
  bool isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    fetchLiveSquad();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (t) => fetchLiveSquad());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchLiveSquad() async {
    final String baseUrl = 'https://the-armoury-api.onrender.com/api/live-squad';
    try {
      final response = await http.get(Uri.parse(baseUrl)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            starters = data['starters'] ?? [];
            substitutes = data['substitutes'] ?? [];
            matchTitle = data['matchName'] ?? "Arsenal Lineup";
            isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Squad Fetch Error: $e");
      // If server fails, stop loading so user doesn't stay on a blank screen
      if (mounted) setState(() => isLoading = false);
    }
  }

  // Helper to sort players based on a preferred role order
  List<dynamic> sortByRole(List<dynamic> players, List<String> roleOrder) {
    List<dynamic> sorted = List.from(players);
    sorted.sort((a, b) {
      int indexA = roleOrder.indexOf(a['role'] ?? '');
      int indexB = roleOrder.indexOf(b['role'] ?? '');
      return indexA.compareTo(indexB);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter and Sort each line
    final gk = starters.where((p) => p['pos'] == 'GK').toList();
    final def = sortByRole(starters.where((p) => p['pos'] == 'DEF').toList(), ['Left Back', 'Center Back', 'Right Back']);
    final mid = sortByRole(starters.where((p) => p['pos'] == 'MID').toList(), ['Central Mid', 'Defensive Mid', 'Attacking Mid']);
    final fwd = sortByRole(starters.where((p) => p['pos'] == 'FWD').toList(), ['Left Winger', 'Striker', 'Right Winger', 'Forward']);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      appBar: AppBar(
        title: const Text("Matchday Squad", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'ClearfaceGothic')),
        backgroundColor: arsenalRed,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: arsenalRed))
          : RefreshIndicator(
              onRefresh: fetchLiveSquad,
              color: arsenalRed,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text("CURRENT LINEUP FOR:", 
                            style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600], fontSize: 10, letterSpacing: 1.2)),
                          Text(matchTitle, 
                            textAlign: TextAlign.center, 
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyLarge?.color, 
                              fontSize: 18, 
                              fontWeight: FontWeight.bold
                            )),
                        ],
                      ),
                    ),
                    
                    // --- THE PITCH ---
                    Container(
                      height: 620,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isDark ? [] : [const BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))]
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          children: [
                            CustomPaint(size: Size.infinite, painter: FootballPitchPainter(isDark: isDark)),
                            
                            // Goalkeeper
                            _pos(gk, 0, 0.50, 0.86), 

                            // Defenders
                            _pos(def, 0, 0.12, 0.70), 
                            _pos(def, 1, 0.37, 0.73), 
                            _pos(def, 2, 0.63, 0.73), 
                            _pos(def, 3, 0.88, 0.70), 

                            // Midfielders
                            _pos(mid, 0, 0.22, 0.50), 
                            _pos(mid, 1, 0.50, 0.54), 
                            _pos(mid, 2, 0.78, 0.50),

                            // Forwards
                            _pos(fwd, 0, 0.18, 0.24), 
                            _pos(fwd, 1, 0.50, 0.16), 
                            _pos(fwd, 2, 0.82, 0.24),
                          ],
                        ),
                      ),
                    ),
                    
                    _buildSubList(context, isDark),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _pos(List<dynamic> list, int idx, double x, double y) {
    if (idx >= list.length) return const SizedBox.shrink();
    return Positioned(
      left: (MediaQuery.of(context).size.width - 24) * x - 35, 
      top: 620 * y - 40,
      child: _buildPlayerWidget(list[idx]),
    );
  }

  Widget _buildPlayerWidget(dynamic player) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, double value, child) => Transform.scale(scale: value, child: child),
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerInfoPage(player: player))),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 28, 
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: NetworkImage(player['image'] ?? 'https://via.placeholder.com/150'),
                    ),
                  ),
                  CircleAvatar(
                    radius: 10, 
                    backgroundColor: arsenalRed, 
                    child: Text(player['number']?.toString() ?? '0', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(4)),
              child: Text(
                (player['name'] ?? 'Player').split(' ').last, 
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubList(BuildContext context, bool isDark) {
    if (substitutes.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(25, 30, 25, 10),
          child: Text("Substitutes", style: TextStyle(color: arsenalRed, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'ClearfaceGothic')),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: substitutes.length,
          itemBuilder: (context, index) {
            final p = substitutes[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
                borderRadius: BorderRadius.circular(15),
                boxShadow: isDark ? [] : [const BoxShadow(color: Colors.black12, blurRadius: 4)]
              ),
              child: ListTile(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerInfoPage(player: p))),
                leading: CircleAvatar(
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                  backgroundImage: NetworkImage(p['image'] ?? 'https://via.placeholder.com/150')
                ),
                title: Text(p['name'] ?? 'Unknown Player', 
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontWeight: FontWeight.bold)),
                subtitle: Text("${p['pos'] ?? 'N/A'} - #${p['number'] ?? '0'}", 
                  style: TextStyle(color: isDark ? Colors.grey : Colors.grey[600])),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
              ),
            );
          },
        ),
      ],
    );
  }
}

class FootballPitchPainter extends CustomPainter {
  final bool isDark;
  FootballPitchPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint grass = Paint()..color = isDark ? const Color(0xFF1B4D3E) : const Color(0xFF2E7D32);
    canvas.drawRRect(RRect.fromLTRBR(0, 0, size.width, size.height, const Radius.circular(20)), grass);
    
    final Paint lines = Paint()..color = Colors.white.withOpacity(isDark ? 0.2 : 0.4)..style = PaintingStyle.stroke..strokeWidth = 2;
    
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), lines);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 60, lines);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.15, 0, size.width * 0.7, size.height * 0.18), lines);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.15, size.height * 0.82, size.width * 0.7, size.height * 0.18), lines);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.3, 0, size.width * 0.4, size.height * 0.06), lines);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.3, size.height * 0.94, size.width * 0.4, size.height * 0.06), lines);
  }
  @override
  bool shouldRepaint(CustomPainter old) => false;
}