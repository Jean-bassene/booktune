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
    return Scaffold(
      appBar: AppBar(
        title: const Text('LibriVox Library'),
        backgroundColor: Colors.deepPurple.shade900,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.purple.shade900,
            ],
          ),
        ),
        child: Column(
          children: [
            _buildSearchUI(),
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'recherche auteur...',
              hintStyle: TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Colors.white54),
                onPressed: () {
                  _searchController.clear();
                  _fetchRecentBooks();
                },
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _performSearch(),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Language:', style: TextStyle(color: Colors.white70)),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  value: _selectedLanguage ?? 'All',
                  dropdownColor: Colors.purple.shade800,
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
      return const Center(child: CircularProgressIndicator());
    }

    if (_books.isEmpty) {
      return Center(
        child: Text(
          _isSearch
              ? 'No results found.'
              : _selectedLanguage != null
                  ? 'No books found in this language.'
                  : 'Could not load recent books.',
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            _isSearch ? 'Search Results' : 'Recently Added',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: Colors.white),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _books.length,
            itemBuilder: (context, index) {
              final book = _books[index];
              return Card(
                color: Colors.white.withOpacity(0.1),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: book.coverUrl != null
                      ? Image.network(
                          book.coverUrl!,
                          width: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.book, color: Colors.white),
                        )
                      : const Icon(Icons.book, color: Colors.white),
                  title: Text(book.title,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(book.author,
                          style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              book.language ?? 'Unknown',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  onTap: () => _playBook(book),
                  trailing: _playingBook == book
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
