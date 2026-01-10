import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/audiobook_provider.dart';
import '../providers/player_provider.dart';
import '../models/audiobook.dart'; // Import direct pour Audiobook
import '../models/ambient_music.dart'; // Import direct pour AmbientMusic
import '../services/file_import_service.dart';
import '../services/android_permissions_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });

    // Charger les livres au démarrage de l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudiobookProvider>().loadAudiobooks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade900,
            Colors.blue.shade900,
            Colors.indigo.shade900,
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAudiobooksTab(context),
                  _buildRecentsTab(context),
                  _buildAmbiancesTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade900.withOpacity(0.5),
            Colors.blue.shade800.withOpacity(0.5),
          ],
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: Colors.blue.shade400,
            width: 3,
          ),
        ),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.book),
                SizedBox(width: 8),
                Text('Livres'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule),
                SizedBox(width: 8),
                Text('Récents'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.music_note),
                SizedBox(width: 8),
                Text('Ambiances'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudiobooksTab(BuildContext context) {
    return Consumer<AudiobookProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        // Filtrer les livres selon la recherche
        final filtered = provider.audiobooks.where((book) {
          return book.title.toLowerCase().contains(_searchQuery) ||
              book.author.toLowerCase().contains(_searchQuery);
        }).toList();

        if (provider.audiobooks.isEmpty) {
          return _buildEmptyState(context);
        }

        if (filtered.isEmpty && _searchQuery.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Aucun résultat',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return _buildAudiobookList(context, provider,
            customList: filtered.isNotEmpty ? filtered : null);
      },
    );
  }

  Widget _buildRecentsTab(BuildContext context) {
    return Consumer<AudiobookProvider>(
      builder: (context, provider, child) {
        // Trier les livres par dernière position (avec position > 0) ou par date d'import
        final recents = List<Audiobook>.from(provider.audiobooks)
          ..sort((a, b) {
            // Priorité aux livres avec position sauvegardée
            if ((a.lastPosition) > 0 && (b.lastPosition) == 0) return -1;
            if ((a.lastPosition) == 0 && (b.lastPosition) > 0) return 1;
            // Sinon tri par date d'import (plus récent en premier)
            return (b.dateImported).compareTo(a.dateImported);
          });

        // Filtrer pour ne montrer que ceux avec position ou avec lecture récente
        var recentlyRead =
            recents.where((book) => book.lastPosition > 0).toList();

        // Appliquer la recherche
        recentlyRead = recentlyRead.where((book) {
          return book.title.toLowerCase().contains(_searchQuery) ||
              book.author.toLowerCase().contains(_searchQuery);
        }).toList();

        if (recentlyRead.isEmpty && _searchQuery.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Aucun livre lu récemment',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (recentlyRead.isEmpty && _searchQuery.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Aucun résultat',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return _buildAudiobookList(context, provider, customList: recentlyRead);
      },
    );
  }

  Widget _buildAmbiancesTab(BuildContext context) {
    return Consumer<AudiobookProvider>(
      builder: (context, provider, child) {
        if (provider.ambientMusic.isEmpty) {
          return _buildEmptyAmbianceState(context);
        }

        return _buildAmbiantList(context, provider);
      },
    );
  }

  Widget _buildEmptyAmbianceState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucune ambiance importée',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Importez des musiques d\'ambiance pour les utiliser',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmbiantList(BuildContext context, AudiobookProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.ambientMusic.length,
      itemBuilder: (context, index) {
        final music = provider.ambientMusic[index];
        return Card(
          color: Colors.grey.shade900,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.purple.shade700, width: 0.5),
          ),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade600, Colors.indigo.shade800],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.music_note, color: Colors.white54),
            ),
            title: Text(
              music.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Ambiance',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.orange),
              onPressed: () {
                _showDeleteAmbianceDialog(context, music);
              },
            ),
            onTap: () {
              context.read<PlayerProvider>().loadAndPlayAmbient(music);
              _tabController.animateTo(0);
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteAmbientMusic(
      BuildContext context, AmbientMusic music) async {
    try {
      final provider = context.read<AudiobookProvider>();
      await provider.deleteAmbientMusic(music.id!);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ambiance supprimée'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showDeleteAmbianceDialog(
    BuildContext context,
    AmbientMusic music,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Supprimer l\'ambiance ?',
            style: TextStyle(color: Colors.white)),
        content: Text(
            'Voulez-vous supprimer "${music.name}" de vos ambiances ?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Annuler', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteAmbientMusic(context, music);
            },
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ma Bibliothèque',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Vos livres audio',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  showMenu<String>(
                    context: context,
                    position: const RelativeRect.fromLTRB(100, 60, 0, 0),
                    items: [
                      const PopupMenuItem(
                        value: 'audiobook',
                        child: Row(
                          children: [
                            Icon(Icons.book, color: Colors.white),
                            SizedBox(width: 12),
                            Text('Importer un livre',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'ambient',
                        child: Row(
                          children: [
                            Icon(Icons.music_note, color: Colors.purple),
                            SizedBox(width: 12),
                            Text('Importer une ambiance',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ).then((value) {
                    if (value == 'audiobook') {
                      _importFiles(context);
                    } else if (value == 'ambient') {
                      _importAmbientMusic(context);
                    }
                  });
                },
                icon: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade400, Colors.pink.shade400],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Rechercher...',
              hintStyle: TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.purple.shade400,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_books_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          const Text(
            'Aucun livre audio',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Importez vos premiers livres audio',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => _importFiles(context),
            icon: const Icon(Icons.add),
            label: const Text('Importer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudiobookList(BuildContext context, AudiobookProvider provider,
      {List<Audiobook>? customList}) {
    final books = customList ?? provider.audiobooks;
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: books.length,
      itemBuilder: (context, index) {
        final audiobook = books[index];
        return _buildAudiobookCard(context, audiobook);
      },
    );
  }

  Widget _buildAudiobookCard(BuildContext context, Audiobook audiobook) {
    final progress = (audiobook.duration ?? 0) > 0
        ? audiobook.lastPosition / (audiobook.duration ?? 1)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.read<PlayerProvider>().loadAndPlayAudiobook(audiobook);
          },
          onLongPress: () {
            _showDeleteDialog(context, audiobook);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade400,
                            Colors.pink.shade400
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.book,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    if (audiobook.isFavorite)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.5),
                                blurRadius: 8,
                              )
                            ],
                          ),
                          padding: const EdgeInsets.all(2),
                          child: const Icon(
                            Icons.star,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        audiobook.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        audiobook.author,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (progress > 0) ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white24,
                          valueColor:
                              AlwaysStoppedAnimation(Colors.purple.shade400),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white70),
                  color: Colors.grey.shade900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) async {
                    if (value == 'play') {
                      context
                          .read<PlayerProvider>()
                          .loadAndPlayAudiobook(audiobook);
                    } else if (value == 'play_amb') {
                      context
                          .read<PlayerProvider>()
                          .loadAndPlayAudiobook(audiobook);
                      _showAmbientPicker(context);
                    } else if (value == 'ambiance') {
                      _showAmbientPicker(context);
                    } else if (value == 'favorite') {
                      context
                          .read<AudiobookProvider>()
                          .toggleFavorite(audiobook.id!);
                    } else if (value == 'delete') {
                      _showDeleteDialog(context, audiobook);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'play',
                      child: Row(
                        children: [
                          Icon(Icons.play_circle_outline,
                              color: Colors.white70),
                          SizedBox(width: 12),
                          Text('Lire', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'play_amb',
                      child: Row(
                        children: [
                          Icon(Icons.playlist_play, color: Colors.white70),
                          SizedBox(width: 12),
                          Text('Lire + Ambiance',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'ambiance',
                      child: Row(
                        children: [
                          Icon(Icons.queue_music, color: Colors.white70),
                          SizedBox(width: 12),
                          Text('Ambiance',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'favorite',
                      child: Row(
                        children: [
                          Icon(
                            audiobook.isFavorite
                                ? Icons.star
                                : Icons.star_outline,
                            color: audiobook.isFavorite
                                ? Colors.amber
                                : Colors.white70,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            audiobook.isFavorite
                                ? 'Retirer des favoris'
                                : 'Ajouter aux favoris',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.remove_circle_outline,
                              color: Colors.orange),
                          SizedBox(width: 12),
                          Text('Retirer',
                              style: TextStyle(color: Colors.orange)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Audiobook audiobook) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Retirer de la bibliothèque ?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Voulez-vous retirer "${audiobook.title}" de votre bibliothèque ? Le fichier restera sur votre téléphone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAudiobook(context, audiobook);
            },
            child: const Text(
              'Retirer',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAudiobook(
      BuildContext context, Audiobook audiobook) async {
    try {
      final provider = context.read<AudiobookProvider>();

      // Supprimer seulement de la base de données (pas le fichier physique)
      await provider.deleteAudiobook(audiobook.id!);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Livre retiré de la bibliothèque'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Erreur suppression: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ignore: unused_element
  void _showImportDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Importer des fichiers audio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Les fichiers seront automatiquement classés',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            _buildImportButton(
              context,
              'Importer des fichiers',
              'MP3, M4A, M4B, OGG, FLAC, WAV',
              Icons.file_upload,
              Colors.purple,
              () => _importFiles(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pop(context);
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importFiles(BuildContext context) async {
    debugPrint('=== DEBUT IMPORT FICHIERS ===');

    // Demander les permissions avant d'importer
    try {
      await AndroidPermissionsService.requestAllPermissions();
    } catch (e) {
      debugPrint('Erreur permissions: $e');
    }

    final importService = FileImportService();
    final provider = context.read<AudiobookProvider>();

    // Ouvrir le sélecteur de fichiers
    final files = await importService.pickAudiobookFiles();
    print('Fichiers sélectionnés: ${files?.length ?? 0}');

    if (files != null && files.isNotEmpty) {
      int audiobooksCount = 0;
      int ambientCount = 0;

      for (var file in files) {
        try {
          //
          debugPrint('Traitement fichier: ${file.path}');

          // Tous les fichiers sont traités comme des livres audio
          final audiobook = await importService.createAudiobookFromFile(file);
          debugPrint('Livre créé: ${audiobook.title}');
          await provider.addAudiobook(audiobook);
          debugPrint('Livre ajouté en BDD');
          audiobooksCount++;
        } catch (e, stackTrace) {
          debugPrint('Erreur import: $e');
          debugPrint('StackTrace: $stackTrace');
        }
      }

      if (context.mounted) {
        if (audiobooksCount > 0) {
          // Recharger les livres depuis la base de données
          await provider.loadAudiobooks();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$audiobooksCount livre(s) importé(s)'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun nouveau livre importé.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else {
      debugPrint('Aucun fichier sélectionné');
    }
    debugPrint('=== FIN IMPORT FICHIERS ===');
  }

  Future<void> _importAmbientMusic(BuildContext context) async {
    debugPrint('=== DEBUT IMPORT MUSIQUE AMBIANCE ===');

    try {
      final importService = FileImportService();
      debugPrint('Service import créé');

      final provider = context.read<AudiobookProvider>();
      debugPrint('Provider récupéré');

      final files = await importService.pickAmbientMusicFiles();
      debugPrint('Fichiers musique sélectionnés: ${files?.length ?? 0}');

      if (files != null && files.isNotEmpty) {
        debugPrint('Traitement de ${files.length} fichier(s)...');

        for (int i = 0; i < files.length; i++) {
          final file = files[i];
          try {
            //
            debugPrint('[$i] Traitement fichier: ${file.path}');
            debugPrint('[$i] Fichier existe: ${await file.exists()}');

            final music = await importService.createAmbientMusicFromFile(file);
            debugPrint('[$i] Musique créée: ${music.name}');

            await provider.addAmbientMusic(music);
            debugPrint('[$i] Musique ajoutée en BDD avec succès');
          } catch (e, stackTrace) {
            debugPrint('[$i] ERREUR lors du traitement: $e');
            debugPrint('[$i] StackTrace: $stackTrace');
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${files.length} musique(s) importée(s)'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        debugPrint('Message de succès affiché');
      } else {
        debugPrint('Aucun fichier musique sélectionné');
      }
    } catch (e, stackTrace) {
      debugPrint('ERREUR GLOBALE import musique: $e');
      debugPrint('StackTrace global: $stackTrace');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }

    debugPrint('=== FIN IMPORT MUSIQUE AMBIANCE ===');
  }

  void _showAmbientPicker(BuildContext context) async {
    final provider = context.read<AudiobookProvider>();
    // Ensure ambient list is loaded
    if (provider.ambientMusic.isEmpty) {
      await provider.loadAmbientMusic();
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const Text('Choisir une ambiance',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 12),
                if (provider.ambientMusic.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Aucune musique d\'ambiance disponible',
                        style: TextStyle(color: Colors.white70)),
                  ),
                ] else ...[
                  for (var music in provider.ambientMusic)
                    ListTile(
                      leading:
                          const Icon(Icons.music_note, color: Colors.white70),
                      title: Text(music.name,
                          style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        context
                            .read<PlayerProvider>()
                            .loadAndPlayAmbient(music);
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: Colors.grey.shade900,
                              title: const Text('Supprimer l\'ambiance ?',
                                  style: TextStyle(color: Colors.white)),
                              content: Text(
                                  'Voulez-vous supprimer "${music.name}" ? Cette action supprimera l\'entrée de la base de données.',
                                  style:
                                      const TextStyle(color: Colors.white70)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Annuler',
                                      style: TextStyle(color: Colors.white70)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Supprimer',
                                      style:
                                          TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _deleteAmbientMusic(context, music);
                            if (mounted) {
                              setState(() {});
                            }
                          }
                        },
                      ),
                    ),
                ],
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.stop, color: Colors.orange),
                  title: const Text('Arrêter l\'ambiance',
                      style: TextStyle(color: Colors.orange)),
                  onTap: () {
                    Navigator.pop(context);
                    context.read<PlayerProvider>().stopAmbient();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
