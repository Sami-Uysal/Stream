import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:stream/core/services/tmdb_service.dart';
import 'package:stream/core/services/image_service.dart';
import 'package:stream/features/home/models/tmdb_media.dart';
import 'package:stream/features/details/movie_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TmdbService _tmdbService = TmdbService();
  final TextEditingController _searchController = TextEditingController();
  
  List<TmdbMedia> _results = [];
  bool _isLoading = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) return;
    if (query.trim() == _lastQuery) return;
    
    setState(() {
      _isLoading = true;
      _lastQuery = query.trim();
    });

    try {
      final results = await _tmdbService.search(query.trim());
      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '${l10n.navSearch}...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[500]),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          onSubmitted: _search,
          onChanged: (value) {
            if (value.length >= 3) {
              _search(value);
            }
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _results = [];
                  _lastQuery = '';
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _search(_searchController.text),
          ),
        ],
      ),
      body: _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _lastQuery.isEmpty ? Icons.search : Icons.search_off,
              size: 80,
              color: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            Text(
              _lastQuery.isEmpty 
                  ? l10n.navSearch
                  : l10n.noContentFound,
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            if (_lastQuery.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Film veya dizi ara',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 180,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final media = _results[index];
        return _buildResultCard(media);
      },
    );
  }

  Widget _buildResultCard(TmdbMedia media) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailScreen(media: media)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    ImageService.getPosterUrl(
                      posterPath: media.posterPath,
                      tmdbId: media.id,
                      mediaType: media.type,
                    ),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.movie, color: Colors.white54, size: 40),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: media.type == 'tv' ? Colors.blue : Colors.purple,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        media.type == 'tv' ? 'TV' : 'Film',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(200),
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            media.voteAverage.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            media.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
