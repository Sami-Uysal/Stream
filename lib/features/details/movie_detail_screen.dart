import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream/core/services/tmdb_service.dart';
import 'package:stream/core/services/plugin_service.dart';
import 'package:stream/core/tmdb/tmdb_constants.dart';
import 'package:stream/features/home/models/tmdb_media.dart';
import 'package:stream/core/services/image_service.dart';
import 'package:stream/features/plugins/models/stream_request.dart';
import 'package:stream/features/plugins/models/stream_response.dart';
import 'package:stream/core/providers/locale_provider.dart';

class MovieDetailScreen extends ConsumerStatefulWidget {
  final TmdbMedia media;

  const MovieDetailScreen({super.key, required this.media});

  @override
  ConsumerState<MovieDetailScreen> createState() => _MovieDetailScreenState();
}

class _MovieDetailScreenState extends ConsumerState<MovieDetailScreen> {
  final TmdbService _tmdbService = TmdbService();
  final PluginService _pluginService = PluginService();
  late Future<TmdbMedia?> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _pluginService.init();
    // Fetch full details (we need IMDb ID etc.)
    _detailsFuture = _tmdbService.getMovieDetails(
      id: widget.media.id, 
      type: widget.media.type,
      // We'll trust the service defaults for now or could pull from provider here
    );
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
                      ids: {
                        'tmdb': media.id,
                        if (media.imdbId != null) 'imdb': media.imdbId!,
                      },
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
    // Re-fetch if locale changes? 
    // Ideally we would watch localeProvider and trigger a new fetch, 
    // but for now let's just use the initial load or pull locale from provider for the API call if we were dynamic.
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<TmdbMedia?>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          final media = snapshot.data ?? widget.media; // Fallback to passed data while loading
          
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 400.0,
                pinned: true,
                backgroundColor: Colors.black,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        ImageService.getBackdropUrl(media.backdropPath),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black],
                            stops: [0.5, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Hero(
                            tag: 'poster_${media.id}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                ImageService.getPosterUrl(media.posterPath),
                                width: 120,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  media.title,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      media.releaseDate.split('-').first,
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    if (media.runtime != null) ...[
                                      const SizedBox(width: 16),
                                      Text(
                                        '${media.runtime} min',
                                        style: const TextStyle(color: Colors.white70),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      media.voteAverage.toStringAsFixed(1),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                    const Text('/10', style: TextStyle(color: Colors.white54)),
                                  ],
                                ),
                                if (media.imdbId != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                            color: Colors.yellow[700],
                                            borderRadius: BorderRadius.circular(4)
                                        ),
                                        child: const Text('IMDb', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12))
                                    )
                                ]
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Overview',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        media.overview,
                        style: const TextStyle(color: Colors.white70, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      if (media.cast != null && media.cast!.isNotEmpty) ...[
                        Text(
                          'Cast',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: media.cast!.length,
                            itemBuilder: (context, index) {
                              final actor = media.cast![index];
                              return Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: Column(
                                  children: [
                                    CircleAvatar(
                                      radius: 30,
                                      backgroundImage: actor.profilePath != null
                                          ? NetworkImage(ImageService.getPosterUrl(actor.profilePath!))
                                          : null,
                                      backgroundColor: Colors.grey[800],
                                      child: actor.profilePath == null ? const Icon(Icons.person, color: Colors.white54) : null,
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: 70,
                                      child: Text(
                                        actor.name,
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _showStreamsModal(context, media),
                          icon: const Icon(Icons.search, color: Colors.black),
                          label: const Text('SEARCH STREAMS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent[400],
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
