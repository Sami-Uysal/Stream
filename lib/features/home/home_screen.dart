import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:stream/core/services/tmdb_service.dart';
import 'package:stream/core/services/plugin_service.dart';
import 'package:stream/core/tmdb/tmdb_constants.dart';
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
  
  late Future<List<TmdbMedia>> _netflixFuture;
  late Future<List<TmdbMedia>> _disneyFuture;
  late Future<List<TmdbMedia>> _primeFuture;
  late Future<List<TmdbMedia>> _trendingFuture;

  final ScrollController _trendingScrollController = ScrollController();
  final ScrollController _netflixScrollController = ScrollController();
  final ScrollController _disneyScrollController = ScrollController();
  final ScrollController _primeScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _pluginService.init();
  }

  @override
  void dispose() {
    _trendingScrollController.dispose();
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
    _trendingFuture = _tmdbService.getTrending();
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
        title: Text(l10n.appTitle),
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
      body: CustomScrollView(
        slivers: [
          _buildSectionTitle(l10n.sectionTrending),
          _buildHorizontalList(_trendingFuture, l10n, _trendingScrollController),

          _buildSectionTitle('Netflix'),
          _buildHorizontalList(_netflixFuture, l10n, _netflixScrollController),
          
          _buildSectionTitle('Disney+'),
          _buildHorizontalList(_disneyFuture, l10n, _disneyScrollController),
          
          _buildSectionTitle('Amazon Prime Video'),
          _buildHorizontalList(_primeFuture, l10n, _primeScrollController),
          
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
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
        height: 250, 
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
            return Stack(
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
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 40,
                  child: _buildScrollButton(
                    icon: Icons.chevron_left,
                    onPressed: () => _scrollList(scrollController, false),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 40,
                  child: _buildScrollButton(
                    icon: Icons.chevron_right,
                    onPressed: () => _scrollList(scrollController, true),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildScrollButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: icon == Icons.chevron_left ? Alignment.centerLeft : Alignment.centerRight,
              end: icon == Icons.chevron_left ? Alignment.centerRight : Alignment.centerLeft,
              colors: [
                Colors.black87,
                Colors.transparent,
              ],
            ),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}
