import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/librivox_service.dart';
import '../models/librivox_book.dart';
import '../providers/player_provider.dart';
import 'librivox_detail_screen.dart';

class OnlineLibraryScreen extends StatefulWidget {
  const OnlineLibraryScreen({super.key});

  @override
  State<OnlineLibraryScreen> createState() => _OnlineLibraryScreenState();
}

class _OnlineLibraryScreenState extends State<OnlineLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<LibrivoxBook> _allBooks = []; // Tous les livres chargés
  List<LibrivoxBook> _books = []; // Livres filtrés
  bool _isLoading = true;
  bool _isSearch = false;
  LibrivoxBook? _playingBook;

  // Filtres
  String? _selectedLanguage;
  final List<String> _supportedLanguages = [
    'All',
    'English',
    'French',
    'Spanish',
    'German',
    'Italian',
    'Portuguese',
    'Russian',
    'Chinese',
    'Japanese',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchRecentBooks();
    });
  }

  Future<void> _playBook(LibrivoxBook book) async {
    setState(() {
      _playingBook = book;
    });

    try {
      final librivoxService =
          Provider.of<LibrivoxService>(context, listen: false);
      // Passer le livre existant pour conserver l'auteur
      final fullBookDetails =
          await librivoxService.getBookDetails(book.id, existingBook: book);

      if (fullBookDetails == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to load full book details.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (fullBookDetails.chapters.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No chapters found for this book.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      context.read<PlayerProvider>().loadAndPlayLibrivoxChapter(
          fullBookDetails, fullBookDetails.chapters.first);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Playing "${fullBookDetails.chapters.first.title}" from "${fullBookDetails.title}"...'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play book: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _playingBook = null;
        });
      }
    }
  }

  Future<void> _fetchRecentBooks() async {
    setState(() {
      _isLoading = true;
      _isSearch = false;
      _books = [];
    });

    try {
      final librivoxService =
          Provider.of<LibrivoxService>(context, listen: false);
      final results = await librivoxService.getRecentBooks();
      if (mounted) {
        setState(() {
          _allBooks = results;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load recent books: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      if (_selectedLanguage == null || _selectedLanguage == 'All') {
        _books = _allBooks;
      } else {
        _books = _allBooks
            .where((book) => book.language == _selectedLanguage)
            .toList();
      }
    });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text;
    if (query.isEmpty) {
      _fetchRecentBooks();
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearch = true;
      _books = [];
    });

    try {
      final librivoxService =
          Provider.of<LibrivoxService>(context, listen: false);
      final results = await librivoxService.searchBooks(query);
      if (mounted) {
        setState(() {
          _allBooks = results;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to perform search: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
            // Header avec titre et bouton debug cache
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Explorer LibriVox',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Bouton debug cache (temporaire)
                  IconButton(
                    onPressed: () async {
                      final service =
                          Provider.of<LibrivoxService>(context, listen: false);
                      service.clearCache();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Cache vidé - Actualisez pour voir les changements'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                      // Recharger les livres
                      _fetchRecentBooks();
                    },
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    tooltip: 'Vider cache et recharger',
                  ),
                ],
              ),
            ),
            // Zone de recherche
            _buildSearchUI(),
            // Liste des résultats
            Expanded(
              child: _buildResultsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchUI() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // Barre de recherche (épaisseur réduite)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {}, // Effet tactile sans action
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Rechercher auteur, titre...',
                    hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.white54, size: 18),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear,
                                color: Colors.white54, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _fetchRecentBooks();
                            },
                          )
                        : null,
                    filled: false,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true, // Réduit encore la hauteur
                  ),
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filtre langue
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Langue:', style: TextStyle(color: Colors.white70)),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: DropdownButton<String>(
                  value: _selectedLanguage ?? 'All',
                  dropdownColor: Colors.grey.shade900,
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox(),
                  icon:
                      const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  items: _supportedLanguages.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedLanguage = newValue == 'All' ? null : newValue;
                        _applyFilters();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_books.isEmpty) {
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
            Text(
              _isSearch
                  ? 'Aucun résultat trouvé'
                  : _selectedLanguage != null
                      ? 'Aucun livre dans cette langue'
                      : 'Impossible de charger les livres récents',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            _isSearch ? 'Résultats de recherche' : 'Ajoutés récemment',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _books.length,
            itemBuilder: (context, index) {
              final book = _books[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => LibrivoxDetailScreen(
                            bookId: book.id,
                            bookTitle: book.title,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Image de couverture
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: book.coverUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      book.coverUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(Icons.book,
                                                  color: Colors.white54),
                                    ),
                                  )
                                : const Icon(Icons.book, color: Colors.white54),
                          ),
                          const SizedBox(width: 16),
                          // Informations du livre
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book.title,
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
                                  book.author,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                // Durée totale + Langue
                                Row(
                                  children: [
                                    if (book.totalDuration != null) ...[
                                      Icon(
                                        Icons.access_time,
                                        size: 12,
                                        color: Colors.white54,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        book.formattedTotalDuration,
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    // Badge langue
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.shade500,
                                            Colors.cyan.shade500,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        book.language ?? 'Inconnue',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Indicateur de lecture
                          if (_playingBook == book)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
