import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:stream/core/services/tmdb_service.dart';
import 'package:stream/core/services/plugin_service.dart';
import 'package:stream/core/services/image_service.dart';
import 'package:stream/core/tmdb/tmdb_constants.dart';
import 'package:stream/core/theme/app_theme.dart';
import 'package:stream/core/providers/library_provider.dart';
import 'package:stream/features/home/models/tmdb_media.dart';
import 'package:stream/features/home/widgets/media_card.dart';
import 'package:stream/core/providers/locale_provider.dart';
import 'package:stream/features/details/movie_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TmdbService _tmdbService = TmdbService();
  final PluginService _pluginService = PluginService();
  
  // Futures
  late Future<List<TmdbMedia>> _trendingFuture;
  late Future<List<TmdbMedia>> _nowPlayingFuture;
  late Future<List<TmdbMedia>> _upcomingFuture;
  late Future<List<TmdbMedia>> _topRatedMoviesFuture;
  late Future<List<TmdbMedia>> _topRatedTvFuture;
  late Future<List<TmdbMedia>> _netflixFuture;
  late Future<List<TmdbMedia>> _disneyFuture;
  late Future<List<TmdbMedia>> _primeFuture;

  // ScrollControllers
  final ScrollController _trendingScrollController = ScrollController();
  final ScrollController _nowPlayingScrollController = ScrollController();
  final ScrollController _upcomingScrollController = ScrollController();
  final ScrollController _topRatedMoviesScrollController = ScrollController();
  final ScrollController _topRatedTvScrollController = ScrollController();
  final ScrollController _netflixScrollController = ScrollController();
  final ScrollController _disneyScrollController = ScrollController();
  final ScrollController _primeScrollController = ScrollController();

  // Scroll state tracking
  final Map<ScrollController, bool> _isAtStart = {};
  final Map<ScrollController, bool> _isAtEnd = {};
  final Set<ScrollController> _hoveringControllers = {};

  // Platform detection
  bool get _isDesktopOrWeb {
    if (kIsWeb) return true;
    try {
      return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _pluginService.init();
    _initAllScrollControllers();
  }

  void _initAllScrollControllers() {
    final controllers = [
      _trendingScrollController,
      _nowPlayingScrollController,
      _upcomingScrollController,
      _topRatedMoviesScrollController,
      _topRatedTvScrollController,
      _netflixScrollController,
      _disneyScrollController,
      _primeScrollController,
    ];
    
    for (final controller in controllers) {
      _isAtStart[controller] = true;
      _isAtEnd[controller] = false;
      controller.addListener(() => _updateScrollState(controller));
    }
  }

  void _updateScrollState(ScrollController controller) {
    if (!controller.hasClients) return;
    
    final isAtStart = controller.position.pixels <= 0;
    final isAtEnd = controller.position.pixels >= controller.position.maxScrollExtent;
    
    if (_isAtStart[controller] != isAtStart || _isAtEnd[controller] != isAtEnd) {
      setState(() {
        _isAtStart[controller] = isAtStart;
        _isAtEnd[controller] = isAtEnd;
      });
    }
  }

  @override
  void dispose() {
    _trendingScrollController.dispose();
    _nowPlayingScrollController.dispose();
    _upcomingScrollController.dispose();
    _topRatedMoviesScrollController.dispose();
    _topRatedTvScrollController.dispose();
    _netflixScrollController.dispose();
    _disneyScrollController.dispose();
    _primeScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchAllCatalogs();
  }

  void _fetchAllCatalogs() {
    final localeState = ref.read(localeProvider);
    final region = localeState.region;

    // Trend - Günlük
    _trendingFuture = _tmdbService.getTrending(timeWindow: 'day');
    
    // Vizyonda & Yakında
    _nowPlayingFuture = _tmdbService.getNowPlaying(region: region);
    _upcomingFuture = _tmdbService.getUpcoming(region: region);
    
    // En Çok Oy Alanlar
    _topRatedMoviesFuture = _tmdbService.getTopRated(type: 'movie');
    _topRatedTvFuture = _tmdbService.getTopRated(type: 'tv');
    
    // Platform Katalogları
    _netflixFuture = _tmdbService.getPlatformCatalog(
      providerId: TmdbConstants.providers['Netflix']!,
      type: 'movie',
      region: region,
    );
    _disneyFuture = _tmdbService.getPlatformCatalog(
      providerId: TmdbConstants.providers['Disney+']!,
      type: 'tv',
      region: region,
    );
    _primeFuture = _tmdbService.getPlatformCatalog(
      providerId: TmdbConstants.providers['Amazon Prime']!,
      type: 'movie',
      region: region,
    );
  }

  void _openDetails(BuildContext context, TmdbMedia media) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailScreen(media: media),
      ),
    );
  }

  void _scrollList(ScrollController controller, bool forward) {
    final currentOffset = controller.offset;
    final viewportWidth = MediaQuery.of(context).size.width;
    final scrollAmount = viewportWidth * 0.8;
    
    final targetOffset = forward 
        ? currentOffset + scrollAmount 
        : currentOffset - scrollAmount;
    
    controller.animateTo(
      targetOffset.clamp(0.0, controller.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch for changes to trigger rebuild/refetch
    ref.listen(localeProvider, (previous, next) {
      if (previous?.region != next.region || previous?.locale != next.locale) {
        setState(() {
          _fetchAllCatalogs();
        });
      }
    });

    final l10n = AppLocalizations.of(context)!;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentDim,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: const Icon(Icons.play_arrow, color: AppTheme.accent, size: 20),
            ),
            const SizedBox(width: 12),
            Text(l10n.appTitle),
          ],
        ),
        centerTitle: isDesktop,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _fetchAllCatalogs();
              });
            },
          )
        ],
      ),
      body: _buildBody(l10n, ref),
    );
  }

  Widget _buildBody(AppLocalizations l10n, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // Continue Watching Section (if any)
        _buildContinueWatchingSection(ref, l10n),

        // 🔥 Bugün Trend
        _buildSectionHeader('Bugün Trend', Icons.local_fire_department),
        _buildHorizontalList(_trendingFuture, l10n, _trendingScrollController),

        // 🎬 Şu An Vizyonda
        _buildSectionHeader('Şu An Vizyonda', Icons.theaters),
        _buildHorizontalList(_nowPlayingFuture, l10n, _nowPlayingScrollController),

        // 📅 Yakında Gelecek
        _buildSectionHeader('Yakında Gelecek', Icons.upcoming),
        _buildHorizontalList(_upcomingFuture, l10n, _upcomingScrollController),

        // ⭐ En Çok Oy Alan Filmler
        _buildSectionHeader('En Çok Oy Alan Filmler', Icons.star),
        _buildHorizontalList(_topRatedMoviesFuture, l10n, _topRatedMoviesScrollController),

        // 📺 En Çok Oy Alan Diziler
        _buildSectionHeader('En Çok Oy Alan Diziler', Icons.star_border),
        _buildHorizontalList(_topRatedTvFuture, l10n, _topRatedTvScrollController),

        // Platform Katalogları
        _buildSectionHeader('Netflix', Icons.tv),
        _buildHorizontalList(_netflixFuture, l10n, _netflixScrollController),
        
        _buildSectionHeader('Disney+', Icons.castle),
        _buildHorizontalList(_disneyFuture, l10n, _disneyScrollController),
        
        _buildSectionHeader('Amazon Prime Video', Icons.shopping_bag),
        _buildHorizontalList(_primeFuture, l10n, _primeScrollController),
        
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildContinueWatchingSection(WidgetRef ref, AppLocalizations l10n) {
    final libraryState = ref.watch(libraryProvider);
    final watchingItems = libraryState.getByStatus(LibraryStatus.watching);
    
    if (watchingItems.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentDim,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: const Icon(Icons.history, color: AppTheme.accent, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  'Kaldığın Yerden Devam Et',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: watchingItems.take(10).length,
              itemBuilder: (context, index) {
                final item = watchingItems[index];
                return _buildContinueWatchingCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueWatchingCard(LibraryItem item) {
    final media = item.media;
    final backdropUrl = ImageService.getBackdropUrl(media.backdropPath);

    return GestureDetector(
      onTap: () => _openDetails(context, media),
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
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
              Container(decoration: AppTheme.gradientOverlay),
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
                            color: AppTheme.accent,
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
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
                      ],
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: Icon(icon, color: Colors.white70, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Tümü', style: TextStyle(color: AppTheme.accent)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.accent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalList(
    Future<List<TmdbMedia>> future, 
    AppLocalizations l10n,
    ScrollController scrollController,
  ) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 300, 
        child: FutureBuilder<List<TmdbMedia>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text(l10n.errorGeneric(snapshot.error.toString())));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text(l10n.noContentFound));
            }

            final items = snapshot.data!;
            
            // Check scroll state after items load
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (scrollController.hasClients) {
                _updateScrollState(scrollController);
              }
            });

            final isHovering = _hoveringControllers.contains(scrollController);
            final isAtStart = _isAtStart[scrollController] ?? true;
            final isAtEnd = _isAtEnd[scrollController] ?? false;

            Widget listContent = Stack(
              children: [
                ListView.builder(
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return MediaCard(
                      media: items[index],
                      onTap: () => _openDetails(context, items[index]),
                    );
                  },
                ),
                // Sol tuş - sadece desktop/web'de ve hover'dayken ve başta değilken
                if (_isDesktopOrWeb)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 90,
                    child: _buildScrollButton(
                      isLeft: true,
                      isVisible: isHovering && !isAtStart,
                      onPressed: () => _scrollList(scrollController, false),
                    ),
                  ),
                // Sağ tuş - sadece desktop/web'de ve hover'dayken ve sonda değilken
                if (_isDesktopOrWeb)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 90,
                    child: _buildScrollButton(
                      isLeft: false,
                      isVisible: isHovering && !isAtEnd,
                      onPressed: () => _scrollList(scrollController, true),
                    ),
                  ),
              ],
            );

            // Desktop/Web için MouseRegion ile hover detection
            if (_isDesktopOrWeb) {
              return MouseRegion(
                onEnter: (_) => setState(() => _hoveringControllers.add(scrollController)),
                onExit: (_) => setState(() => _hoveringControllers.remove(scrollController)),
                child: listContent,
              );
            }

            return listContent;
          },
        ),
      ),
    );
  }

  Widget _buildScrollButton({
    required bool isLeft,
    required bool isVisible,
    required VoidCallback onPressed,
  }) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !isVisible,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onPressed,
            child: Container(
              width: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                  end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
                  colors: [
                    Colors.black.withAlpha(200),
                    Colors.black.withAlpha(100),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Center(
                child: Icon(
                  isLeft ? Icons.chevron_left : Icons.chevron_right,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
