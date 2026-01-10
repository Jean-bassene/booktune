import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audiobook_provider.dart';
import 'library_screen.dart';
import 'player_screen.dart';
import 'online_library_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;

  final List<Widget> _screens = [
    const LibraryScreen(),
    const PlayerScreen(),
    const OnlineLibraryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);

    // Charger les données immédiatement au démarrage
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    print('🏠 HomeScreen: Chargement des données au démarrage...');

    final provider = context.read<AudiobookProvider>();
    await provider.loadAudiobooks();
    await provider.loadAmbientMusic();

    // Vérifier que les données sont chargées
    print('🏠 HomeScreen: ${provider.audiobooks.length} livres chargés');
    print('🏠 HomeScreen: ${provider.ambientMusic.length} musiques chargées');

    // Forcer une mise à jour de l'interface
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900.withOpacity(0.8),
              Colors.blue.shade900,
            ],
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          backgroundColor: Colors.transparent,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white54,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books),
              label: 'Bibliothèque',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.play_circle),
              label: 'Lecteur',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.public),
              label: 'Explorer',
            ),
          ],
        ),
      ),
    );
  }
}
