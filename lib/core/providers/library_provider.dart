import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stream/features/home/models/tmdb_media.dart';

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

  const LibraryState({
    this.items = const [],
    this.isLoading = true,
  });

  LibraryState copyWith({
    List<LibraryItem>? items,
    bool? isLoading,
  }) {
    return LibraryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
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

  @override
  LibraryState build() {
    _loadFromStorage();
    return const LibraryState();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        final items = jsonList.map((e) => LibraryItem.fromJson(e)).toList();
        state = state.copyWith(items: items, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print('Error loading library: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.items.map((e) => e.toJson()).toList();
      await prefs.setString(_storageKey, json.encode(jsonList));
    } catch (e) {
      print('Error saving library: $e');
    }
  }

  Future<void> addToLibrary(TmdbMedia media, LibraryStatus status) async {
    // Check if already exists
    final existingIndex = state.items.indexWhere(
      (item) => item.media.id == media.id && item.media.type == media.type
    );

    if (existingIndex != -1) {
      // Update status if already exists
      final updatedItems = [...state.items];
      updatedItems[existingIndex] = state.items[existingIndex].copyWith(status: status);
      state = state.copyWith(items: updatedItems);
    } else {
      // Add new item
      final newItem = LibraryItem(
        media: media,
        status: status,
        addedAt: DateTime.now(),
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
    
    await _saveToStorage();
  }

  Future<void> updateStatus(int mediaId, String type, LibraryStatus newStatus) async {
    final updatedItems = state.items.map((item) {
      if (item.media.id == mediaId && item.media.type == type) {
        return item.copyWith(status: newStatus);
      }
      return item;
    }).toList();
    
    state = state.copyWith(items: updatedItems);
    await _saveToStorage();
  }

  Future<void> removeFromLibrary(int mediaId, String type) async {
    final updatedItems = state.items
        .where((item) => !(item.media.id == mediaId && item.media.type == type))
        .toList();
    
    state = state.copyWith(items: updatedItems);
    await _saveToStorage();
  }

  LibraryStatus? getStatus(int mediaId, String type) {
    final item = state.findItem(mediaId, type);
    return item?.status;
  }
}

final libraryProvider = NotifierProvider<LibraryNotifier, LibraryState>(() {
  return LibraryNotifier();
});
