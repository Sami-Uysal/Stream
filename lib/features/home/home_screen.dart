import 'package:flutter/material.dart';
import 'package:stream/core/services/tmdb_service.dart';
import 'package:stream/core/tmdb/tmdb_constants.dart';
import 'package:stream/features/home/models/tmdb_media.dart';
import 'package:stream/features/home/widgets/media_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TmdbService _tmdbService = TmdbService();
  
  late Future<List<TmdbMedia>> _netflixFuture;
  late Future<List<TmdbMedia>> _disneyFuture;
  late Future<List<TmdbMedia>> _primeFuture;
  late Future<List<TmdbMedia>> _trendingFuture;

  @override
  void initState() {
    super.initState();
    _fetchAllCatalogs();
  }

  void _fetchAllCatalogs() {
    _netflixFuture = _tmdbService.getPlatformCatalog(
      providerId: TmdbConstants.providers['Netflix']!,
      type: 'movie',
    );
    _disneyFuture = _tmdbService.getPlatformCatalog(
      providerId: TmdbConstants.providers['Disney+']!,
      type: 'tv',
    );
    _primeFuture = _tmdbService.getPlatformCatalog(
      providerId: TmdbConstants.providers['Amazon Prime']!,
      type: 'movie',
    );
    _trendingFuture = _tmdbService.getTrending();
  }

  @override
  Widget build(BuildContext context) {
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
          _buildSectionTitle('Trending on Netflix'),
          _buildHorizontalList(_netflixFuture),
          
          _buildSectionTitle('New on Disney+'),
          _buildHorizontalList(_disneyFuture),
          
          _buildSectionTitle('Amazon Prime Movies'),
          _buildHorizontalList(_primeFuture),
          
          _buildSectionTitle('Box Office Hits'),
          _buildHorizontalList(_trendingFuture),
          
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
        height: 250, // Card height + text + spacing
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
                  onTap: () {
                    // Navigate to details (Future step)
                    debugPrint('Tapped: ${items[index].title}');
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
