import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/librivox_book.dart';
import '../providers/player_provider.dart';
import '../services/librivox_service.dart';
import '../services/download_service.dart';

class LibrivoxDetailScreen extends StatefulWidget {
  final String bookId;
  final String bookTitle;

  const LibrivoxDetailScreen({
    super.key,
    required this.bookId,
    required this.bookTitle,
  });

  @override
  State<LibrivoxDetailScreen> createState() => _LibrivoxDetailScreenState();
}

class _LibrivoxDetailScreenState extends State<LibrivoxDetailScreen> {
  LibrivoxBook? _book;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchBookDetails();
    });
  }

  Future<void> _fetchBookDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final librivoxService =
          Provider.of<LibrivoxService>(context, listen: false);
      final book = await librivoxService.getBookDetails(widget.bookId);
      if (mounted) {
        setState(() {
          _book = book;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load book details: $e'),
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
        title: Text(widget.bookTitle),
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
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_book == null) {
      return const Center(
        child: Text(
          'Failed to load book details.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Text(
            'Chapters',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildChapterList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Informations du livre
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_book!.coverUrl != null)
              Image.network(
                _book!.coverUrl!,
                height: 150,
                width: 100,
                fit: BoxFit.cover,
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _book!.title,
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _book!.author,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Language: ${_book!.language}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.white60),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _book!.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white60),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Boutons d'action
        Row(
          children: [
            // Bouton Jouer
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _playBook(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Jouer le livre'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Bouton Télécharger
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _downloadBook(),
                icon: const Icon(Icons.download),
                label: const Text('Télécharger'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Joue le livre complet (commence par le premier chapitre)
  Future<void> _playBook() async {
    if (_book == null || _book!.chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun chapitre disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final firstChapter = _book!.chapters.first;
    context
        .read<PlayerProvider>()
        .loadAndPlayLibrivoxChapter(_book!, firstChapter);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lecture de "${_book!.title}"...'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Télécharge le livre complet
  Future<void> _downloadBook() async {
    if (_book == null) return;

    try {
      // Afficher un dialogue de confirmation
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: Row(
            children: [
              Icon(Icons.download, color: Colors.green.shade400),
              const SizedBox(width: 8),
              const Text('Télécharger le livre',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            'Voulez-vous télécharger "${_book!.title}" pour une écoute hors-ligne ?\n\n'
            'Cela peut prendre quelques minutes selon la taille du livre.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
              ),
              child: const Text('Télécharger'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Initialiser le téléchargement
      final downloadService =
          Provider.of<DownloadService>(context, listen: false);
      await downloadService.initialize();

      // Afficher la progression
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Téléchargement démarré...'),
            duration: Duration(seconds: 2),
          ),
        );

        // Naviguer vers l'écran de progression ou afficher un indicateur
        // TODO: Implémenter écran de progression des téléchargements
      }

      // Démarrer le téléchargement en arrière-plan
      await downloadService.downloadBook(_book!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${_book!.title}" téléchargé avec succès !'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de téléchargement: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildChapterList() {
    if (_book!.chapters.isEmpty) {
      return const Text('No chapters found.',
          style: TextStyle(color: Colors.white70));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _book!.chapters.length,
      itemBuilder: (context, index) {
        final chapter = _book!.chapters[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text('${index + 1}'),
          ),
          title:
              Text(chapter.title, style: const TextStyle(color: Colors.white)),
          onTap: () {
            context
                .read<PlayerProvider>()
                .loadAndPlayLibrivoxChapter(_book!, chapter);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Playing "${chapter.title}"...'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }
}
