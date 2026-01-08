import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/librivox_book.dart';
import '../providers/player_provider.dart';
import '../services/librivox_service.dart';

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
      final librivoxService = Provider.of<LibrivoxService>(context, listen: false);
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 16),
          _buildChapterList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                _book!.author,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                'Language: ${_book!.language}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
              ),
              const SizedBox(height: 16),
              Text(
                _book!.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChapterList() {
    if (_book!.chapters.isEmpty) {
      return const Text('No chapters found.', style: TextStyle(color: Colors.white70));
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
          title: Text(chapter.title, style: const TextStyle(color: Colors.white)),
          onTap: () {
            context.read<PlayerProvider>().loadAndPlayLibrivoxChapter(_book!, chapter);
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
