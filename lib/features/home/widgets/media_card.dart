import 'package:flutter/material.dart';
import 'package:stream/core/services/image_service.dart';
import 'package:stream/core/theme/app_theme.dart';
import 'package:stream/features/home/models/tmdb_media.dart';

class MediaCard extends StatelessWidget {
  final TmdbMedia media;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final bool showBadge;

  const MediaCard({
    super.key,
    required this.media,
    this.width = 140,
    this.height = 210,
    this.onTap,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = ImageService.getPosterUrl(
      posterPath: media.posterPath,
      tmdbId: media.id,
      mediaType: media.type,
    );

    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: height,
            child: GestureDetector(
              onTap: onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Poster image
                    Container(
                      color: Colors.grey[900],
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                    child: Icon(Icons.broken_image, color: Colors.white38),
                                  ),
                            )
                          : const Center(
                              child: Icon(Icons.movie, color: Colors.white38, size: 40),
                            ),
                    ),
                    
                    // Type badge (top-left)
                    if (showBadge)
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
                    

                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36, // 2 satır için sabit yükseklik (13px × 1.4 lineHeight × 2)
            child: Align(
              alignment: Alignment.topLeft,
              child: Text(
                media.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (media.releaseDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              media.releaseDate.split('-').first,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
