import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';

// Navigation Imports
import '../standingsPage.dart';
import '../profile_page.dart'; 
import '../settings_page.dart';
import '../squad_page.dart'; 
import '../player_profile_page.dart'; 
import '../matches_page.dart'; 
import '../login_page.dart'; 

// Info Page Imports
import '../history_page.dart';
import '../trophies_page.dart';
import '../invincible_season_page.dart';
import '../about_us_page.dart'; 

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  final Color arsenalRed = const Color(0xFFEF0107);
  final String footballApiKey = "2ea9d9d1d87642518ad04dbe96346339"; 
  final String arsenalId = "57"; 
  final String backendBaseUrl = 'https://the-armoury-api.onrender.com';

  List<dynamic> players = [];
  List<dynamic> filteredPlayers = []; 
  bool _isAppLoading = true; 
  bool isLoadingPlayers = true;
  bool _isGuest = false; 
  final TextEditingController searchController = TextEditingController();

  Timer? _scoreTimer; 
  Map<String, dynamic>? liveMatch;
  bool _isSpoilerModeOn = false;
  bool _tempReveal = false;

  String _userName = "Gooner";
  String? _userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _initializeApp();
    setupNotifications();
    
    _scoreTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      fetchLiveScore();
    });
  }

  @override
  void dispose() {
    _scoreTimer?.cancel(); 
    searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await _loadLocalSettings();
    if (mounted) setState(() => _isAppLoading = false); 
    fetchSquad();
    fetchLiveScore();
    _fetchUserProfileFromCloud(); 
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSpoilerModeOn = prefs.getBool('spoilers') ?? false;
      _userName = prefs.getString('display_name') ?? "Gooner";
      _isGuest = prefs.getBool('is_guest') ?? false; 
    });
  }

  Future<void> _fetchUserProfileFromCloud() async {
    try {
      String deviceId = await _getDeviceId();
      final response = await http.get(Uri.parse('$backendBaseUrl/api/user/profile/$deviceId'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _userName = data['displayName'] ?? _userName;
            _userPhotoUrl = data['profilePicUrl'];
          });
        }
      }
    } catch (e) {
      debugPrint("Cloud Profile Fetch Error: $e");
    }
  }

  Future<String> _getDeviceId() async {
    var deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      var androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else {
      var iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "unknown_device";
    }
  }

  void setupNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    try {
      await messaging.subscribeToTopic("arsenal_updates");
    } catch (e) {
      debugPrint("❌ Notification Error: $e");
    }
  }

  Future<void> fetchLiveScore() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.football-data.org/v4/teams/$arsenalId/matches?status=IN_PLAY'),
        headers: {'X-Auth-Token': footballApiKey},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final matches = data['matches'] as List;
        if (mounted) {
          setState(() {
            liveMatch = matches.isNotEmpty ? matches[0] : null;
          });
        }
      }
    } catch (e) {
      debugPrint("Live Score Error: $e");
    }
  }

  Future<void> fetchSquad() async {
    try {
      final response = await http.get(Uri.parse('$backendBaseUrl/api/squad'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            players = json.decode(response.body);
            filteredPlayers = players; 
            isLoadingPlayers = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingPlayers = false);
    }
  }

  void _filterPlayers(String query) {
    setState(() {
      filteredPlayers = players
          .where((player) => player['name']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<Map<String, dynamic>> fetchNextMatch() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.football-data.org/v4/teams/$arsenalId/matches?status=SCHEDULED&limit=1'),
        headers: {'X-Auth-Token': footballApiKey},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final matches = data['matches'] as List;
        if (matches.isNotEmpty) return matches[0];
      }
      return {'error': 'No upcoming matches'};
    } catch (e) {
      return {'error': 'Error fetching match'};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAppLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: arsenalRed)),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: _buildDrawer(context),
      appBar: appbar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          search(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _initializeApp(),
              color: arsenalRed,
              child: SingleChildScrollView(
                // ✅ ADDED: Bouncing Scroll Physics
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    liveScoreWidget(), 
                    squad(context), 
                    matchesSection(),      
                    standings(context),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget liveScoreWidget() {
    if (liveMatch == null) return const SizedBox.shrink();
    final homeScore = liveMatch!['score']['fullTime']['home'] ?? 0;
    final awayScore = liveMatch!['score']['fullTime']['away'] ?? 0;
    final status = liveMatch!['status'] == 'PAUSED' ? "HT" : "LIVE";

    // ✅ ADDED: Elastic Entrance Bounce
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 800),
      tween: Tween<double>(begin: 0.8, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, double value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFEF0107), Color(0xFF910104)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildLiveTeam(liveMatch!['homeTeam']['shortName'], liveMatch!['homeTeam']['crest']),
            GestureDetector(
              onTap: () { if(_isSpoilerModeOn) setState(() => _tempReveal = !_tempReveal); },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
                    // ✅ FIXED: Removed 'const' for variable text
                    child: Text(status, style: const TextStyle(color: Color(0xFFEF0107), fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                  const SizedBox(height: 10),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Text("$homeScore - $awayScore", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      if (_isSpoilerModeOn && !_tempReveal)
                        _buildSpoilerBlur(),
                    ],
                  ),
                ],
              ),
            ),
            _buildLiveTeam(liveMatch!['awayTeam']['shortName'], liveMatch!['awayTeam']['crest']),
          ],
        ),
      ),
    );
  }

  Widget _buildSpoilerBlur() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          color: Colors.black.withOpacity(0.3),
          child: const Text("SCORE HIDDEN", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: arsenalRed),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: (_userPhotoUrl != null)
                  ? NetworkImage('$backendBaseUrl$_userPhotoUrl')
                  : const NetworkImage('https://img.freepik.com/premium-vector/man-avatar-profile-picture-vector-illustration_268834-538.jpg'),
            ),
            accountName: Text(_userName, style: const TextStyle(fontFamily: 'ClearfaceGothic', fontWeight: FontWeight.bold, fontSize: 18)),
            accountEmail: Text(_isGuest ? "Guest Mode" : "Victoria Concordia Crescit", style: const TextStyle(color: Colors.white70)),
          ),
          if (_isGuest)
            _buildMenuItem(context, Icons.login, 'Sign In / Register', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
            }),
          _buildMenuItem(context, Icons.person, 'My Profile', () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())).then((_) => _initializeApp());
          }),
          _buildMenuItem(context, Icons.history, 'History', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HistoryPage()))),
          _buildMenuItem(context, Icons.emoji_events, 'Trophies', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TrophiesPage()))),
          _buildMenuItem(context, Icons.star, 'Invincibles Season', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InvinciblesPage()))),
          _buildMenuItem(context, Icons.info_outline, 'About Us', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutUsPage()))), 
          const Divider(),
          _buildMenuItem(context, Icons.settings, 'Settings', () {
            Navigator.pop(context); 
            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsPage())).then((_) => _loadLocalSettings());
          }),
        ],
      ),
    );
  }

  Widget squad(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, 'Squad', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SquadPage()))),
        const SizedBox(height: 15),
        SizedBox(
          height: 200.0,
          child: isLoadingPlayers
              ? Center(child: CircularProgressIndicator(color: arsenalRed))
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  itemCount: filteredPlayers.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 15),
                  itemBuilder: (context, index) {
                    final player = filteredPlayers[index];
                    return _playerCard(context, player);
                  },
                ),
        ),
      ],
    );
  }

  Widget _playerCard(BuildContext context, dynamic player) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerInfoPage(player: player))),
      child: Container(
        width: 140,
        decoration: _cardDecoration(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ Hero widget for bouncy navigation
            Hero(
              tag: player['name'],
              child: CircleAvatar(radius: 40, backgroundColor: isDark ? Colors.grey[800] : Colors.grey[300], backgroundImage: NetworkImage(player['image'] ?? '')),
            ),
            const SizedBox(height: 10),
            Text(player['name'], textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color)), 
            Text("No. ${player['number']}", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600], fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 25.0, top: 10.0),
      child: GestureDetector(
        onTap: onTap,
        child: Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'ClearfaceGothic', color: Theme.of(context).textTheme.bodyLarge?.color)),
      ),
    );
  }

  Widget matchesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, 'Matches', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MatchesPage()))),
        const SizedBox(height: 15),
        FutureBuilder<Map<String, dynamic>>(
          future: fetchNextMatch(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(margin: const EdgeInsets.symmetric(horizontal: 25), height: 160, decoration: _cardDecoration(context), child: const Center(child: CircularProgressIndicator()));
            }
            final match = snapshot.data!;
            if (match.containsKey('error')) return const SizedBox.shrink();
            return _nextMatchCard(context, match);
          },
        ),
      ],
    );
  }

  Widget _nextMatchCard(BuildContext context, Map<String, dynamic> match) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          Text(match['competition']['name'], style: TextStyle(color: arsenalRed, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTeamColumn(context, match['homeTeam']['name'], match['homeTeam']['crest']),
              Text("VS", style: TextStyle(color: arsenalRed, fontSize: 20, fontWeight: FontWeight.bold)),
              _buildTeamColumn(context, match['awayTeam']['name'], match['awayTeam']['crest']),
            ],
          ),
        ],
      ),
    );
  }

  Widget standings(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 25.0, top: 20.0),
          child: Text('Standings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, fontFamily: 'ClearfaceGothic', color: Theme.of(context).textTheme.bodyLarge?.color)),
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Row(
            children: [
              Expanded(child: _buildStandingCard(title: "Premier\nLeague", imagePath: 'https://upload.wikimedia.org/wikipedia/en/thumb/f/f2/Premier_League_Logo.svg/300px-Premier_League_Logo.svg.png', color: const Color(0xFF38003c), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StandingsPage(initialIndex: 0))))),
              const SizedBox(width: 15),
              Expanded(child: _buildStandingCard(title: "Champions\nLeague", imagePath: 'https://upload.wikimedia.org/wikipedia/commons/f/f3/Logo_UEFA_Champions_League.png?20230107004614', color: const Color(0xFF001f46), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const StandingsPage(initialIndex: 1))))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveTeam(String name, String? crest) {
    return Column(
      children: [
        if (crest != null) Image.network(crest, height: 45, width: 45, errorBuilder: (c, o, s) => const Icon(Icons.shield, color: Colors.white)),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }

  Widget _buildTeamColumn(BuildContext context, String name, String? crestUrl) {
    return Expanded(child: Column(children: [SizedBox(height: 50, width: 50, child: (crestUrl != null && !crestUrl.endsWith('.svg')) ? Image.network(crestUrl) : const Icon(Icons.shield, color: Colors.white)), const SizedBox(height: 8), Text(name == "Arsenal FC" ? "Arsenal" : name, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis)]));
  }

  Widget _buildStandingCard({required String title, required String imagePath, required Color color, required VoidCallback onTap}) {
    return GestureDetector(onTap: onTap, child: Container(height: 160, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [CircleAvatar(radius: 35, backgroundColor: Colors.white, child: Padding(padding: const EdgeInsets.all(8.0), child: Image.network(imagePath, fit: BoxFit.contain))), const SizedBox(height: 15), Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))])));
  }

  AppBar appbar() {
    return AppBar(
      backgroundColor: arsenalRed, 
      elevation: 0, 
      leading: IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () => _scaffoldKey.currentState?.openDrawer()), 
      title: const Text('Arsenal F.C'), 
      centerTitle: true, 
      titleTextStyle: const TextStyle(fontFamily: 'ClearfaceGothic', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)
    );
  }

  Widget search() {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.all(16.0), 
      child: TextField(
        controller: searchController, 
        onChanged: _filterPlayers, 
        style: TextStyle(color: isDark ? Colors.white : Colors.black), 
        decoration: InputDecoration(
          filled: true, 
          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0), borderSide: BorderSide.none), 
          prefixIcon: Icon(Icons.search, color: isDark ? Colors.white70 : Colors.black54), 
          hintText: 'Search Players', 
          hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
          suffixIcon: searchController.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { searchController.clear(); _filterPlayers(''); }) : null
        )
      )
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, color: isDark ? Colors.white : Colors.black87), 
      title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 16)), 
      onTap: onTap
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white, 
      borderRadius: BorderRadius.circular(20),
      boxShadow: isDark ? [] : [const BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))], 
    );
  }
}