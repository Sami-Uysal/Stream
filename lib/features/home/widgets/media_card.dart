import 'package:flutter/material.dart';
import 'package:stream/core/services/image_service.dart';
import 'package:stream/features/home/models/tmdb_media.dart';

class MediaCard extends StatelessWidget {
  final TmdbMedia media;
  final double width;
  final double height;
  final VoidCallback? onTap;

  const MediaCard({
    super.key,
    required this.media,
    this.width = 140,
    this.height = 210,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = ImageService.getPosterUrl(
      posterPath: media.posterPath,
      tmdbId: media.id,
    );

    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.grey[900],
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              const Center(child: Icon(Icons.broken_image)),
                        )
                      : const Center(child: Icon(Icons.movie)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            media.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
