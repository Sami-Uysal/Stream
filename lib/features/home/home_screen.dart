import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  @override
  void initState() {
    super.initState();
    _pluginService.init();
    // Initial fetch will happen in didChangeDependencies or build if we want it reactive
    // But since initState is one-time, we'll call a fetch method that we can also call on refresh
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchAllCatalogs();
  }

  void _fetchAllCatalogs() {
    // Access provider state via ref (read is fine here if triggered by build/dependency change, 
    // but better to watch in build or just read current state here since didChangeDependencies is called).
    // Actually, to make it reactive to provider changes without full rebuild, we might just use ref.watch in build 
    // but dealing with Futures in build is tricky.
    // Let's grab current state.
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stream'),
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
          _buildSectionTitle('Trending'),
          _buildHorizontalList(_trendingFuture),

          _buildSectionTitle('Netflix'),
          _buildHorizontalList(_netflixFuture),
          
          _buildSectionTitle('Disney+'),
          _buildHorizontalList(_disneyFuture),
          
          _buildSectionTitle('Amazon Prime Video'),
          _buildHorizontalList(_primeFuture),
          
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

  Widget _buildHorizontalList(Future<List<TmdbMedia>> future) {
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
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No content found'));
            }

            final items = snapshot.data!;
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return MediaCard(
                  media: items[index],
                  onTap: () => _openDetails(context, items[index]),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
