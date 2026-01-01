import 'package:flutter/material.dart';
import 'package:stream/core/services/tmdb_service.dart';
import 'package:stream/core/services/plugin_service.dart';
import 'package:stream/core/tmdb/tmdb_constants.dart';
import 'package:stream/features/home/models/tmdb_media.dart';
import 'package:stream/features/home/widgets/media_card.dart';
import 'package:stream/features/plugins/models/stream_request.dart';
import 'package:stream/features/plugins/models/stream_response.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    _fetchAllCatalogs();
  }

  void _fetchAllCatalogs() {
    // Using TR specific logic implicitly via TmdbService defaults, 
    // but explicit titles in UI.
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

  void _showStreamsModal(BuildContext context, TmdbMedia media) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Sources for ${media.title}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<StreamResponse>>(
                    future: _pluginService.getAllStreams(StreamRequest(
                      type: media.type,
                      ids: {'tmdb': media.id}, // In real app, fetch external IDs
                      title: media.title,
                      year: int.tryParse(media.releaseDate.split('-').first),
                    )),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Searching all providers...', style: TextStyle(color: Colors.white70)),
                            ],
                          ),
                        );
                      }
                      
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                      }

                      final streams = snapshot.data ?? [];
                      
                      if (streams.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off, size: 48, color: Colors.white54),
                              const SizedBox(height: 16),
                              const Text('No streams found.', style: TextStyle(color: Colors.white70)),
                              TextButton(
                                onPressed: () async {
                                  // Temporary debug to install a plugin
                                  await _pluginService.installPlugin('https://raw.githubusercontent.com/mowli/stream-plugins/main/test_plugin.js');
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                  }
                                }, 
                                child: const Text('Install Test Plugin (Debug)')
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: scrollController,
                        itemCount: streams.length,
                        itemBuilder: (context, index) {
                          final stream = streams[index];
                          return ListTile(
                            leading: const Icon(Icons.play_circle_fill, color: Colors.teal),
                            title: Text(stream.name, style: const TextStyle(color: Colors.white)),
                            subtitle: Text(stream.description, style: const TextStyle(color: Colors.white70)),
                            onTap: () {
                               // Handle playing stream
                               Navigator.pop(context);
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(content: Text('Playing: ${stream.url}')),
                               );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stream TR'),
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
          _buildSectionTitle('Trending in Turkey'),
          _buildHorizontalList(_trendingFuture),

          _buildSectionTitle('Netflix Turkey'),
          _buildHorizontalList(_netflixFuture),
          
          _buildSectionTitle('Disney+ New Arrivals'),
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
                  onTap: () => _showStreamsModal(context, items[index]),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
