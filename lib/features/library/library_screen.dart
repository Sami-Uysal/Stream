import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:stream/core/providers/library_provider.dart';
import 'package:stream/core/services/image_service.dart';
import 'package:stream/features/details/movie_detail_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  LibraryStatus? _selectedStatus;
  bool _isGridView = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LibraryItem> _getFilteredItems(LibraryState state) {
    var items = _selectedStatus == null 
        ? state.items 
        : state.getByStatus(_selectedStatus!);
    
    if (_searchQuery.isNotEmpty) {
      items = items.where((item) => 
        item.media.title.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final libraryState = ref.watch(libraryProvider);
    final filteredItems = _getFilteredItems(libraryState);
    final watchingItems = libraryState.getByStatus(LibraryStatus.watching);

    return Scaffold(
      body: libraryState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  title: Text(l10n.navLibrary),
                  actions: [
                    IconButton(
                      icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                      onPressed: () => setState(() => _isGridView = !_isGridView),
                    ),
                  ],
                ),

                SliverToBoxAdapter(
                  child: _buildStatisticsSection(libraryState, l10n),
                ),

                if (watchingItems.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      child: Text(
                        'Kaldığın Yerden Devam Et',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildContinueWatchingSection(watchingItems, l10n),
                  ),
                ],

                SliverToBoxAdapter(
                  child: _buildSearchAndFilters(libraryState, l10n),
                ),

                if (filteredItems.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(l10n),
                  )
                else if (_isGridView)
                  _buildGridContent(filteredItems, l10n)
                else
                  _buildListContent(filteredItems, l10n),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }

  Widget _buildStatisticsSection(LibraryState state, AppLocalizations l10n) {
    final movieCount = state.items.where((i) => i.media.type == 'movie').length;
    final tvCount = state.items.where((i) => i.media.type == 'tv').length;
    final completedCount = state.getByStatus(LibraryStatus.completed).length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.movie_outlined,
            value: '$movieCount',
            label: 'Film',
            color: Colors.purple,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.tv_outlined,
            value: '$tvCount',
            label: 'Dizi',
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.check_circle_outline,
            value: '$completedCount',
            label: 'Tamamlandı',
            color: Colors.green,
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.bookmark,
            value: '${state.items.length}',
            label: 'Toplam',
            color: Colors.tealAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueWatchingSection(List<LibraryItem> items, AppLocalizations l10n) {
    final displayItems = items.take(10).toList();
    
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: displayItems.length,
        itemBuilder: (context, index) {
          final item = displayItems[index];
          return _buildContinueWatchingCard(item, l10n);
        },
      ),
    );
  }

  Widget _buildContinueWatchingCard(LibraryItem item, AppLocalizations l10n) {
    final media = item.media;
    final backdropUrl = ImageService.getBackdropUrl(media.backdropPath);

    return GestureDetector(
      onTap: () => _openDetails(media),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              backdropUrl.isNotEmpty
                  ? Image.network(
                      backdropUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.movie, size: 40, color: Colors.white38),
                      ),
                    )
                  : Container(
                      color: Colors.grey[800],
                      child: const Icon(Icons.movie, size: 40, color: Colors.white38),
                    ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withAlpha(220),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      media.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.tealAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow, color: Colors.black, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Devam Et',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => _showItemOptions(item, l10n),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.more_vert, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(LibraryState state, AppLocalizations l10n) {
    final filters = [
      (null, 'Tümü', Icons.apps),
      (LibraryStatus.watching, l10n.statusWatching, Icons.play_circle_outline),
      (LibraryStatus.completed, l10n.statusCompleted, Icons.check_circle_outline),
      (LibraryStatus.onHold, l10n.statusOnHold, Icons.pause_circle_outline),
      (LibraryStatus.dropped, l10n.statusDropped, Icons.cancel_outlined),
      (LibraryStatus.planned, l10n.statusPlanned, Icons.schedule),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '${l10n.navSearch}...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          const SizedBox(height: 16),
          
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              itemBuilder: (context, index) {
                final filter = filters[index];
                final isSelected = _selectedStatus == filter.$1;
                final count = filter.$1 == null 
                    ? state.items.length 
                    : state.getByStatus(filter.$1!).length;

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
                    label: Text('${filter.$2} ($count)'),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.grey[300],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.grey[850],
                    selectedColor: Colors.tealAccent,
                    side: BorderSide(
                      color: isSelected ? Colors.tealAccent : Colors.grey[700]!,
                    ),
                    onSelected: (_) {
                      setState(() => _selectedStatus = filter.$1);
                    },
                  ),
                );
              },
            ),
          ),
        ],
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
              color: Colors.grey[900],
              shape: BoxShape.circle,
            ),
            child: Icon(
              _selectedStatus != null ? Icons.filter_list_off : Icons.bookmark_border,
              size: 60,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedStatus != null ? l10n.noItemsInCategory : l10n.libraryEmpty,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedStatus != null 
                ? 'Farklı bir filtre deneyin'
                : l10n.libraryEmptyHint,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGridContent(List<LibraryItem> items, AppLocalizations l10n) {
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
          (context, index) => _buildModernGridCard(items[index], l10n),
          childCount: items.length,
        ),
      ),
    );
  }

  Widget _buildModernGridCard(LibraryItem item, AppLocalizations l10n) {
    final media = item.media;

    return GestureDetector(
      onTap: () => _openDetails(media),
      onLongPress: () => _showItemOptions(item, l10n),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
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
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(180),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: media.type == 'tv' ? Colors.blue : Colors.purple,
                        borderRadius: BorderRadius.circular(6),
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
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(item.status),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStatusIcon(item.status),
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
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
                  if (item.status == LibraryStatus.watching)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.tealAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.black, size: 16),
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

  Widget _buildListContent(List<LibraryItem> items, AppLocalizations l10n) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _buildListCard(items[index], l10n),
        childCount: items.length,
      ),
    );
  }

  Widget _buildListCard(LibraryItem item, AppLocalizations l10n) {
    final media = item.media;

    return GestureDetector(
      onTap: () => _openDetails(media),
      onLongPress: () => _showItemOptions(item, l10n),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[850]!),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
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
                          color: media.type == 'tv' ? Colors.blue : Colors.purple,
                          borderRadius: BorderRadius.circular(4),
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getStatusColor(item.status).withAlpha(50),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _getStatusColor(item.status)),
                        ),
                        child: Text(
                          _getStatusText(item.status, l10n),
                          style: TextStyle(
                            color: _getStatusColor(item.status),
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
                      const Icon(Icons.star, color: Colors.amber, size: 14),
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
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onPressed: () => _showItemOptions(item, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(LibraryStatus status) {
    switch (status) {
      case LibraryStatus.watching:
        return Colors.tealAccent;
      case LibraryStatus.completed:
        return Colors.green;
      case LibraryStatus.onHold:
        return Colors.orange;
      case LibraryStatus.dropped:
        return Colors.red;
      case LibraryStatus.planned:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(LibraryStatus status) {
    switch (status) {
      case LibraryStatus.watching:
        return Icons.play_arrow;
      case LibraryStatus.completed:
        return Icons.check;
      case LibraryStatus.onHold:
        return Icons.pause;
      case LibraryStatus.dropped:
        return Icons.close;
      case LibraryStatus.planned:
        return Icons.schedule;
    }
  }

  String _getStatusText(LibraryStatus status, AppLocalizations l10n) {
    switch (status) {
      case LibraryStatus.watching:
        return l10n.statusWatching;
      case LibraryStatus.completed:
        return l10n.statusCompleted;
      case LibraryStatus.onHold:
        return l10n.statusOnHold;
      case LibraryStatus.dropped:
        return l10n.statusDropped;
      case LibraryStatus.planned:
        return l10n.statusPlanned;
    }
  }

  void _openDetails(dynamic media) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MovieDetailScreen(media: media)),
    );
  }

  void _showItemOptions(LibraryItem item, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          ImageService.getPosterUrl(
                            posterPath: item.media.posterPath,
                            tmdbId: item.media.id,
                            mediaType: item.media.type,
                          ),
                          width: 50,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 50,
                            height: 70,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.media.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(item.status).withAlpha(50),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getStatusText(item.status, l10n),
                                style: TextStyle(
                                  color: _getStatusColor(item.status),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.grey),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.tealAccent.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.swap_horiz, color: Colors.tealAccent),
                  ),
                  title: Text(l10n.changeStatus, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    'Mevcut: ${_getStatusText(item.status, l10n)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showStatusPicker(item, l10n);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: Text(l10n.removeFromLibrary, style: const TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(libraryProvider.notifier).removeFromLibrary(
                      item.media.id,
                      item.media.type,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.removedFromLibrary(item.media.title)),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showStatusPicker(LibraryItem item, AppLocalizations l10n) {
    final statuses = [
      (LibraryStatus.watching, l10n.statusWatching, Icons.play_circle_outline, Colors.tealAccent),
      (LibraryStatus.completed, l10n.statusCompleted, Icons.check_circle_outline, Colors.green),
      (LibraryStatus.onHold, l10n.statusOnHold, Icons.pause_circle_outline, Colors.orange),
      (LibraryStatus.dropped, l10n.statusDropped, Icons.cancel_outlined, Colors.red),
      (LibraryStatus.planned, l10n.statusPlanned, Icons.schedule, Colors.blue),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.selectStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: statuses.map((status) {
                      final isSelected = item.status == status.$1;
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          ref.read(libraryProvider.notifier).updateStatus(
                            item.media.id,
                            item.media.type,
                            status.$1,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? status.$4.withAlpha(30) : Colors.grey[850],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? status.$4 : Colors.grey[700]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(status.$3, color: status.$4, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                status.$2,
                                style: TextStyle(
                                  color: isSelected ? status.$4 : Colors.white,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                Icon(Icons.check, color: status.$4, size: 18),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
