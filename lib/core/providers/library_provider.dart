import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream/features/home/models/tmdb_media.dart';
import 'package:stream/core/services/sync_service.dart';
import 'package:stream/core/services/sync_queue_service.dart';
import 'package:stream/core/services/tmdb_service.dart';

enum SyncPhase { fetching, enriching, saving, completed }

class SyncProgress {
  final int total;
  final int current;
  final String? currentTitle;
  final SyncPhase phase;

  const SyncProgress({
    this.total = 0,
    this.current = 0,
    this.currentTitle,
    this.phase = SyncPhase.fetching,
  });

  double get percentage => total > 0 ? current / total : 0;

  SyncProgress copyWith({
    int? total,
    int? current,
    String? currentTitle,
    SyncPhase? phase,
  }) {
    return SyncProgress(
      total: total ?? this.total,
      current: current ?? this.current,
      currentTitle: currentTitle ?? this.currentTitle,
      phase: phase ?? this.phase,
    );
  }
}

enum LibraryStatus {
  watching,
  completed,
  onHold,
  dropped,
  planned,
}

class LibraryItem {
  final TmdbMedia media;
  final LibraryStatus status;
  final DateTime addedAt;

  LibraryItem({
    required this.media,
    required this.status,
    required this.addedAt,
  });

  Map<String, dynamic> toJson() => {
    'media': media.toJson(),
    'status': status.index,
    'addedAt': addedAt.toIso8601String(),
  };

  factory LibraryItem.fromJson(Map<String, dynamic> json) {
    return LibraryItem(
      media: TmdbMedia.fromStorageJson(json['media']),
      status: LibraryStatus.values[json['status']],
      addedAt: DateTime.parse(json['addedAt']),
    );
  }

  LibraryItem copyWith({
    TmdbMedia? media,
    LibraryStatus? status,
    DateTime? addedAt,
  }) {
    return LibraryItem(
      media: media ?? this.media,
      status: status ?? this.status,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

class LibraryState {
  final List<LibraryItem> items;
  final bool isLoading;
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final SyncProgress? syncProgress;

  const LibraryState({
    this.items = const [],
    this.isLoading = true,
    this.isSyncing = false,
    this.lastSyncTime,
    this.syncProgress,
  });

  LibraryState copyWith({
    List<LibraryItem>? items,
    bool? isLoading,
    bool? isSyncing,
    DateTime? lastSyncTime,
    SyncProgress? syncProgress,
    bool clearSyncProgress = false,
  }) {
    return LibraryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      syncProgress: clearSyncProgress ? null : (syncProgress ?? this.syncProgress),
    );
  }

  List<LibraryItem> getByStatus(LibraryStatus status) {
    return items.where((item) => item.status == status).toList();
  }

  LibraryItem? findItem(int mediaId, String type) {
    try {
      return items.firstWhere((item) => item.media.id == mediaId && item.media.type == type);
    } catch (_) {
      return null;
    }
  }

  bool isInLibrary(int mediaId, String type) {
    return items.any((item) => item.media.id == mediaId && item.media.type == type);
  }
}

class LibraryNotifier extends Notifier<LibraryState> {
  static const String _storageKey = 'library_items';
  static const String _enrichQueueKey = 'enrich_queue';
  static const int _batchSize = 50;
  static const Duration _baseDelay = Duration(milliseconds: 300);
  static const int _maxRetries = 3;
  
  SyncService? _syncService;
  final TmdbService _tmdbService = TmdbService();
  bool _cancelSync = false;

  @override
  LibraryState build() {
    _loadFromStorage();
    return const LibraryState();
  }

  void setSyncService(SyncService? service) {
    _syncService = service;
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      final lastSync = await SyncQueueService.getLastSyncTime();
      
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        final items = jsonList.map((e) => LibraryItem.fromJson(e)).toList();
        state = state.copyWith(items: items, isLoading: false, lastSyncTime: lastSync);
      } else {
        state = state.copyWith(isLoading: false, lastSyncTime: lastSync);
      }
    } catch (e) {
      debugPrint('Error loading library: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.items.map((e) => e.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('Error saving library: $e');
    }
  }

  Future<void> addToLibrary(TmdbMedia media, LibraryStatus status, {bool syncToRemote = true}) async {
    final existingIndex = state.items.indexWhere(
      (item) => item.media.id == media.id && item.media.type == media.type
    );

    if (existingIndex != -1) {
      final updatedItems = [...state.items];
      updatedItems[existingIndex] = state.items[existingIndex].copyWith(status: status);
      state = state.copyWith(items: updatedItems);
    } else {
      final newItem = LibraryItem(
        media: media,
        status: status,
        addedAt: DateTime.now(),
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
    
    await _saveToStorage();

    if (syncToRemote && _syncService != null) {
      final success = await _syncService!.setStatus(media, status);
      if (!success) {
        await SyncQueueService.addOperation(SyncOperation(
          operationType: SyncOperationType.updateStatus,
          mediaId: media.id,
          mediaType: media.type,
          mediaTitle: media.title,
          status: status.name,
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  Future<void> updateStatus(int mediaId, String type, LibraryStatus newStatus, {bool syncToRemote = true}) async {
    final item = state.findItem(mediaId, type);
    if (item == null) return;

    final updatedItems = state.items.map((item) {
      if (item.media.id == mediaId && item.media.type == type) {
        return item.copyWith(status: newStatus);
      }
      return item;
    }).toList();
    
    state = state.copyWith(items: updatedItems);
    await _saveToStorage();

    if (syncToRemote && _syncService != null) {
      final success = await _syncService!.setStatus(item.media, newStatus);
      if (!success) {
        await SyncQueueService.addOperation(SyncOperation(
          operationType: SyncOperationType.updateStatus,
          mediaId: mediaId,
          mediaType: type,
          mediaTitle: item.media.title,
          status: newStatus.name,
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  Future<void> removeFromLibrary(int mediaId, String type, {bool syncToRemote = true}) async {
    final item = state.findItem(mediaId, type);
    if (item == null) return;

    final updatedItems = state.items
        .where((item) => !(item.media.id == mediaId && item.media.type == type))
        .toList();
    
    state = state.copyWith(items: updatedItems);
    await _saveToStorage();

    if (syncToRemote && _syncService != null) {
      final success = await _syncService!.removeFromWatchlist(item.media);
      if (!success) {
        await SyncQueueService.addOperation(SyncOperation(
          operationType: SyncOperationType.removeFromWatchlist,
          mediaId: mediaId,
          mediaType: type,
          mediaTitle: item.media.title,
          timestamp: DateTime.now(),
        ));
      }
    }
  }

  Future<void> clearAll() async {
    state = state.copyWith(items: []);
    await _saveToStorage();
  }

  LibraryStatus? getStatus(int mediaId, String type) {
    final item = state.findItem(mediaId, type);
    return item?.status;
  }

  Future<TmdbMedia?> _enrichWithTmdbDetails(SyncItem syncItem, {int retryCount = 0}) async {
    try {
      final type = syncItem.mediaType == 'movie' ? 'movie' : 'tv';
      final details = await _tmdbService.getMovieDetails(
        id: syncItem.tmdbId,
        type: type,
      );
      return details;
    } catch (e) {
      if (retryCount < _maxRetries) {
        final delay = _baseDelay * (1 << retryCount);
        debugPrint('TMDB retry ${retryCount + 1}/$_maxRetries for ${syncItem.title} in ${delay.inMilliseconds}ms');
        await Future.delayed(delay);
        return _enrichWithTmdbDetails(syncItem, retryCount: retryCount + 1);
      }
      debugPrint('TMDB failed after $_maxRetries retries: ${syncItem.title}');
      await _addToEnrichQueue(syncItem);
      return null;
    }
  }

  Future<void> _addToEnrichQueue(SyncItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList(_enrichQueueKey) ?? [];
    final key = '${item.tmdbId}_${item.mediaType}';
    if (!queue.contains(key)) {
      queue.add(key);
      await prefs.setStringList(_enrichQueueKey, queue);
    }
  }

  Future<List<String>> _getEnrichQueue() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_enrichQueueKey) ?? [];
  }

  Future<void> _clearEnrichQueue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_enrichQueueKey);
  }

  void cancelSync() {
    _cancelSync = true;
  }

  Future<void> syncFromRemote() async {
    if (_syncService == null) return;

    _cancelSync = false;
    state = state.copyWith(
      isSyncing: true,
      syncProgress: const SyncProgress(phase: SyncPhase.fetching),
    );

    try {
      final remoteItems = await _syncService!.getAllItems();
      final total = remoteItems.length;
      
      debugPrint('Sync: Found $total items from remote');
      
      if (_cancelSync) {
        state = state.copyWith(isSyncing: false, clearSyncProgress: true);
        return;
      }

      state = state.copyWith(
        syncProgress: SyncProgress(
          total: total,
          current: 0,
          phase: SyncPhase.enriching,
        ),
      );

      final itemsToEnrich = <SyncItem>[];
      for (final syncItem in remoteItems) {
        if (syncItem.tmdbId == 0) continue;
        final mediaType = syncItem.mediaType == 'movie' ? 'movie' : 'tv';
        final existingItem = state.findItem(syncItem.tmdbId, mediaType);
        
        if (existingItem == null || existingItem.media.posterPath.isEmpty) {
          itemsToEnrich.add(syncItem);
        } else {
          final libraryStatus = syncItem.toLibraryStatus();
          if (libraryStatus != null && existingItem.status != libraryStatus) {
            await updateStatus(syncItem.tmdbId, mediaType, libraryStatus, syncToRemote: false);
          }
        }
      }

      debugPrint('Sync: ${itemsToEnrich.length} items need TMDB enrichment');

      state = state.copyWith(
        syncProgress: SyncProgress(
          total: itemsToEnrich.length,
          current: 0,
          phase: SyncPhase.enriching,
        ),
      );

      int failedCount = 0;
      for (var i = 0; i < itemsToEnrich.length; i++) {
        if (_cancelSync) {
          debugPrint('Sync: Cancelled by user at ${i + 1}/${itemsToEnrich.length}');
          break;
        }

        final syncItem = itemsToEnrich[i];
        
        state = state.copyWith(
          syncProgress: state.syncProgress?.copyWith(
            current: i + 1,
            currentTitle: syncItem.title,
          ),
        );

        final libraryStatus = syncItem.toLibraryStatus();
        if (libraryStatus == null) continue;

        final mediaType = syncItem.mediaType == 'movie' ? 'movie' : 'tv';
        
        TmdbMedia? media = await _enrichWithTmdbDetails(syncItem);
        
        if (media == null) {
          failedCount++;
          media = TmdbMedia(
            id: syncItem.tmdbId,
            title: syncItem.title,
            posterPath: '',
            backdropPath: '',
            overview: '',
            releaseDate: '',
            voteAverage: 0,
            type: mediaType,
            imdbId: syncItem.imdbId,
          );
        }

        await addToLibrary(media, libraryStatus, syncToRemote: false);

        if (i < itemsToEnrich.length - 1) {
          await Future.delayed(_baseDelay);
        }

        if ((i + 1) % _batchSize == 0) {
          await _saveToStorage();
          debugPrint('Sync: Saved batch at ${i + 1}/${itemsToEnrich.length}');
        }
      }

      state = state.copyWith(
        syncProgress: SyncProgress(
          total: itemsToEnrich.length,
          current: itemsToEnrich.length,
          phase: SyncPhase.saving,
        ),
      );

      await _saveToStorage();
      await SyncQueueService.setLastSyncTime(DateTime.now());
      
      state = state.copyWith(
        isSyncing: false,
        lastSyncTime: DateTime.now(),
        clearSyncProgress: true,
      );
      
      if (failedCount > 0) {
        debugPrint('Sync: Completed with $failedCount failed enrichments (queued for retry)');
      } else {
        debugPrint('Sync: Completed successfully');
      }
    } catch (e) {
      debugPrint('Sync from remote error: $e');
      state = state.copyWith(isSyncing: false, clearSyncProgress: true);
    }
  }

  Future<void> processPendingSync() async {
    if (_syncService == null) return;

    await SyncQueueService.processPendingOperations(_syncService!);
  }
}

final libraryProvider = NotifierProvider<LibraryNotifier, LibraryState>(() {
  return LibraryNotifier();
});
