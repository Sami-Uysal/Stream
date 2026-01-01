import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:stream/core/services/tmdb_service.dart';
import 'package:stream/core/services/plugin_service.dart';
import 'package:stream/core/providers/library_provider.dart';
import 'package:stream/core/theme/app_theme.dart';
import 'package:stream/features/home/models/tmdb_media.dart';
import 'package:stream/core/services/image_service.dart';
import 'package:stream/features/plugins/models/stream_request.dart';
import 'package:stream/features/plugins/models/stream_response.dart';

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
    _detailsFuture = _tmdbService.getMovieDetails(
      id: widget.media.id, 
      type: widget.media.type,
    );
  }

  void _showStreamsModal(BuildContext context, TmdbMedia media) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusRound)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Column(
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
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          child: Image.network(
                            ImageService.getPosterUrl(
                              posterPath: media.posterPath,
                              tmdbId: media.id,
                              mediaType: media.type,
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
                                l10n.sourcesFor(media.title),
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
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.grey),
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
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(l10n.searchingProviders, style: const TextStyle(color: Colors.white70)),
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
                              Text(l10n.noStreamsFound, style: const TextStyle(color: Colors.white70)),
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
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withAlpha(30),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              ),
                              child: const Icon(Icons.play_circle_fill, color: AppTheme.accent),
                            ),
                            title: Text(stream.name, style: const TextStyle(color: Colors.white)),
                            subtitle: Text(stream.description, style: TextStyle(color: Colors.grey[500])),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                               Navigator.pop(context);
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                   content: Text(l10n.playingStream(stream.url)),
                                   behavior: SnackBarBehavior.floating,
                                 ),
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
          ),
        );
      },
    );
  }

  Widget _buildLibraryButton(BuildContext context, TmdbMedia media, AppLocalizations l10n) {
    final libraryState = ref.watch(libraryProvider);
    final isInLibrary = libraryState.isInLibrary(media.id, media.type);
    final currentStatus = ref.read(libraryProvider.notifier).getStatus(media.id, media.type);

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => _showAddToLibraryModal(context, media, l10n, currentStatus),
        icon: Icon(
          isInLibrary ? Icons.bookmark : Icons.bookmark_border,
          color: isInLibrary ? AppTheme.accent : Colors.white70,
        ),
        label: Text(
          isInLibrary ? '${l10n.inLibrary} (${_getStatusText(currentStatus!, l10n)})' : l10n.addToLibrary,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isInLibrary ? AppTheme.accent : Colors.white70,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: isInLibrary ? AppTheme.accent : Colors.white38),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
        ),
      ),
    );
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

  void _showAddToLibraryModal(BuildContext context, TmdbMedia media, AppLocalizations l10n, LibraryStatus? currentStatus) {
    final statuses = [
      (LibraryStatus.watching, l10n.statusWatching, Icons.play_circle_outline, AppTheme.statusWatching),
      (LibraryStatus.completed, l10n.statusCompleted, Icons.check_circle_outline, AppTheme.statusCompleted),
      (LibraryStatus.onHold, l10n.statusOnHold, Icons.pause_circle_outline, AppTheme.statusOnHold),
      (LibraryStatus.dropped, l10n.statusDropped, Icons.cancel_outlined, AppTheme.statusDropped),
      (LibraryStatus.planned, l10n.statusPlanned, Icons.schedule, AppTheme.statusPlanned),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusRound)),
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
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        child: Image.network(
                          ImageService.getPosterUrl(
                            posterPath: media.posterPath,
                            tmdbId: media.id,
                            mediaType: media.type,
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
                              media.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            if (currentStatus != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.getStatusColor(currentStatus.name).withAlpha(50),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                ),
                                child: Text(
                                  _getStatusText(currentStatus, l10n),
                                  style: TextStyle(
                                    color: AppTheme.getStatusColor(currentStatus.name),
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
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.selectStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
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
                      final isSelected = currentStatus == status.$1;
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          ref.read(libraryProvider.notifier).addToLibrary(media, status.$1);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.addedToLibrary(media.title)),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? status.$4.withAlpha(30) : AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
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
                if (currentStatus != null) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(libraryProvider.notifier).removeFromLibrary(media.id, media.type);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.removedFromLibrary(media.title)),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete_outline, color: AppTheme.statusDropped),
                        label: Text(l10n.removeFromLibrary, style: const TextStyle(color: AppTheme.statusDropped)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.statusDropped),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<TmdbMedia?>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          final media = snapshot.data ?? widget.media;

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
                                ImageService.getPosterUrl(
                                  posterPath: media.posterPath,
                                  tmdbId: media.id,
                                  mediaType: media.type,
                                ),
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
                                        l10n.runtimeMinutes(media.runtime!),
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
                        l10n.overview,
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
                          l10n.cast,
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
                                          ? NetworkImage(ImageService.getProfileUrl(actor.profilePath!))
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
                      _buildLibraryButton(context, media, l10n),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _showStreamsModal(context, media),
                          icon: const Icon(Icons.play_arrow, color: Colors.black),
                          label: Text(l10n.searchStreams, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLarge)),
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
