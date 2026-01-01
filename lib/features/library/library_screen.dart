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

class _LibraryScreenState extends ConsumerState<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final libraryState = ref.watch(libraryProvider);

    final tabs = [
      (LibraryStatus.watching, l10n.statusWatching, Icons.play_circle_outline),
      (LibraryStatus.completed, l10n.statusCompleted, Icons.check_circle_outline),
      (LibraryStatus.onHold, l10n.statusOnHold, Icons.pause_circle_outline),
      (LibraryStatus.dropped, l10n.statusDropped, Icons.cancel_outlined),
      (LibraryStatus.planned, l10n.statusPlanned, Icons.schedule),
    ];

    return Scaffold(
      body: Column(
        children: [
          // Search bar area (like CloudStream)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.bookmark, color: Colors.tealAccent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: '${l10n.navSearch}...',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (value) {},
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.sort, color: Colors.white70),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: libraryState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : libraryState.items.isEmpty
                    ? _buildEmptyState(l10n)
                    : _buildLibraryContent(libraryState, tabs, l10n),
          ),
          
          // Bottom tabs (like CloudStream)
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              border: Border(
                top: BorderSide(color: Colors.grey[800]!, width: 0.5),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              indicatorColor: Colors.tealAccent,
              labelColor: Colors.tealAccent,
              unselectedLabelColor: Colors.grey[500],
              dividerColor: Colors.transparent,
              tabs: tabs.map((tab) => Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tab.$2),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${libraryState.getByStatus(tab.$1).length}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              )).toList(),
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
          Icon(Icons.bookmark_border, size: 80, color: Colors.grey[700]),
          const SizedBox(height: 16),
          Text(
            l10n.libraryEmpty,
            style: TextStyle(color: Colors.grey[500], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.libraryEmptyHint,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryContent(
    LibraryState libraryState,
    List<(LibraryStatus, String, IconData)> tabs,
    AppLocalizations l10n,
  ) {
    return TabBarView(
      controller: _tabController,
      children: tabs.map((tab) {
        final items = libraryState.getByStatus(tab.$1);
        
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tab.$3, size: 60, color: Colors.grey[700]),
                const SizedBox(height: 12),
                Text(
                  l10n.noItemsInCategory,
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            childAspectRatio: 0.65,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildLibraryCard(item, l10n);
          },
        );
      }).toList(),
    );
  }

  Widget _buildLibraryCard(LibraryItem item, AppLocalizations l10n) {
    final media = item.media;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MovieDetailScreen(media: media),
          ),
        );
      },
      onLongPress: () => _showItemOptions(item, l10n),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
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
                  // Type badge
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            media.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showItemOptions(LibraryItem item, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
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
                  item.media.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(color: Colors.grey),
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: Colors.tealAccent),
                title: Text(l10n.changeStatus, style: const TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showStatusPicker(item, l10n);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(l10n.removeFromLibrary, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(libraryProvider.notifier).removeFromLibrary(
                    item.media.id,
                    item.media.type,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.removedFromLibrary(item.media.title))),
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showStatusPicker(LibraryItem item, AppLocalizations l10n) {
    final statuses = [
      (LibraryStatus.watching, l10n.statusWatching, Icons.play_circle_outline),
      (LibraryStatus.completed, l10n.statusCompleted, Icons.check_circle_outline),
      (LibraryStatus.onHold, l10n.statusOnHold, Icons.pause_circle_outline),
      (LibraryStatus.dropped, l10n.statusDropped, Icons.cancel_outlined),
      (LibraryStatus.planned, l10n.statusPlanned, Icons.schedule),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
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
              const Divider(color: Colors.grey),
              ...statuses.map((status) => ListTile(
                leading: Icon(
                  status.$3,
                  color: item.status == status.$1 ? Colors.tealAccent : Colors.white70,
                ),
                title: Text(
                  status.$2,
                  style: TextStyle(
                    color: item.status == status.$1 ? Colors.tealAccent : Colors.white,
                  ),
                ),
                trailing: item.status == status.$1
                    ? const Icon(Icons.check, color: Colors.tealAccent)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(libraryProvider.notifier).updateStatus(
                    item.media.id,
                    item.media.type,
                    status.$1,
                  );
                },
              )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
