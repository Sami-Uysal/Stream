import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:stream/core/services/tmdb_service.dart';
import 'package:stream/core/services/image_service.dart';
import 'package:stream/core/theme/app_theme.dart';
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
  String _selectedFilter = 'all'; // all, movie, tv
  bool _isGridView = true;

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

  List<TmdbMedia> get _filteredResults {
    if (_selectedFilter == 'all') return _results;
    return _results.where((m) => m.type == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: Text(l10n.navSearch),
            actions: [
              IconButton(
                icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                onPressed: () => setState(() => _isGridView = !_isGridView),
              ),
            ],
          ),
          
          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Film veya dizi ara...',
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _results = [];
                                _lastQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: _search,
                  onChanged: (value) {
                    setState(() {});
                    if (value.length >= 3) {
                      _search(value);
                    }
                  },
                ),
              ),
            ),
          ),
          
          // Filter chips
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFilterChips(l10n),
            ),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
          
          // Content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredResults.isEmpty)
            SliverFillRemaining(child: _buildEmptyState(l10n))
          else if (_isGridView)
            _buildGridContent()
          else
            _buildListContent(),
            
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations l10n) {
    final movieCount = _results.where((m) => m.type == 'movie').length;
    final tvCount = _results.where((m) => m.type == 'tv').length;
    
    final filters = [
      ('all', 'Tümü', Icons.apps, _results.length),
      ('movie', 'Film', Icons.movie_outlined, movieCount),
      ('tv', 'Dizi', Icons.tv_outlined, tvCount),
    ];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter.$1;

          return Padding(
            padding: EdgeInsets.only(right: index < filters.length - 1 ? 8 : 0),
            child: FilterChip(
              selected: isSelected,
              showCheckmark: false,
              avatar: Icon(
                filter.$3,
                size: 18,
                color: isSelected ? Colors.black : Colors.grey[400],
              ),
              label: Text('${filter.$2} (${filter.$4})'),
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : Colors.grey[300],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: AppTheme.surfaceLight,
              selectedColor: AppTheme.accent,
              side: BorderSide(
                color: isSelected ? AppTheme.accent : Colors.grey[700]!,
              ),
              onSelected: (_) {
                setState(() => _selectedFilter = filter.$1);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _lastQuery.isEmpty ? Icons.search : Icons.search_off,
              size: 60,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _lastQuery.isEmpty ? 'Keşfetmeye Başla' : l10n.noContentFound,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _lastQuery.isEmpty 
                ? 'Film veya dizi aramak için yukarıdaki arama çubuğunu kullan'
                : 'Farklı anahtar kelimeler deneyin',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGridContent() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          childAspectRatio: 0.55,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildGridCard(_filteredResults[index]),
          childCount: _filteredResults.length,
        ),
      ),
    );
  }

  Widget _buildGridCard(TmdbMedia media) {
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
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
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
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(decoration: AppTheme.gradientOverlay),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: media.type == 'tv' ? AppTheme.tvBadge : AppTheme.movieBadge,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
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
                  if (media.voteAverage > 0)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: AppTheme.ratingColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            media.voteAverage.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            media.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            media.releaseDate.isNotEmpty ? media.releaseDate.split('-').first : '',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent() {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildListCard(_filteredResults[index]),
        childCount: _filteredResults.length,
      ),
    );
  }

  Widget _buildListCard(TmdbMedia media) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MovieDetailScreen(media: media)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: Colors.grey[850]!),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              child: Image.network(
                ImageService.getPosterUrl(
                  posterPath: media.posterPath,
                  tmdbId: media.id,
                  mediaType: media.type,
                ),
                width: 70,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 70,
                  height: 100,
                  color: Colors.grey[800],
                  child: const Icon(Icons.movie, color: Colors.white54),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: media.type == 'tv' ? AppTheme.tvBadge : AppTheme.movieBadge,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: Text(
                          media.type == 'tv' ? 'TV' : 'Film',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    media.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppTheme.ratingColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        media.voteAverage.toStringAsFixed(1),
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      if (media.releaseDate.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.calendar_today, color: Colors.grey[600], size: 12),
                        const SizedBox(width: 4),
                        Text(
                          media.releaseDate.split('-').first,
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
