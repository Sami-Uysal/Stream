import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream/core/services/trakt_auth_service.dart';
import 'package:stream/core/services/simkl_auth_service.dart';
import 'package:stream/core/services/secure_storage_service.dart';
import 'package:stream/core/services/sync_service.dart';
import 'package:stream/core/services/trakt_sync_service.dart';
import 'package:stream/core/services/simkl_sync_service.dart';

class AuthState {
  final TraktUser? traktUser;
  final SimklUser? simklUser;
  final SyncProvider activeSyncProvider;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.traktUser,
    this.simklUser,
    this.activeSyncProvider = SyncProvider.none,
    this.isLoading = false,
    this.error,
  });

  bool get isTraktConnected => traktUser != null;
  bool get isSimklConnected => simklUser != null;
  bool get hasSyncEnabled => activeSyncProvider != SyncProvider.none;

  SyncService? get syncService {
    switch (activeSyncProvider) {
      case SyncProvider.trakt:
        return TraktSyncService();
      case SyncProvider.simkl:
        return SimklSyncService();
      case SyncProvider.none:
        return null;
    }
  }

  AuthState copyWith({
    TraktUser? traktUser,
    SimklUser? simklUser,
    SyncProvider? activeSyncProvider,
    bool? isLoading,
    String? error,
    bool clearTraktUser = false,
    bool clearSimklUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      traktUser: clearTraktUser ? null : (traktUser ?? this.traktUser),
      simklUser: clearSimklUser ? null : (simklUser ?? this.simklUser),
      activeSyncProvider: activeSyncProvider ?? this.activeSyncProvider,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
_initializeAuth();
    return const AuthState(isLoading: true);
  }

  Future<void> _initializeAuth() async {
    try {
      TraktUser? traktUser;
      SimklUser? simklUser;
      SyncProvider syncProvider = SyncProvider.none;

      if (await TraktAuthService.isConnected()) {
        final username = await TraktAuthService.getCachedUsername();
        if (username != null) {
          traktUser = TraktUser(username: username);
        }
      }

      if (await SimklAuthService.isConnected()) {
        final username = await SimklAuthService.getCachedUsername();
        if (username != null) {
          simklUser = SimklUser(username: username);
        }
      }

      final savedProvider = await SecureStorageService.getActiveSyncProvider();
      if (savedProvider == 'trakt' && traktUser != null) {
        syncProvider = SyncProvider.trakt;
      } else if (savedProvider == 'simkl' && simklUser != null) {
        syncProvider = SyncProvider.simkl;
      }

      state = AuthState(
        traktUser: traktUser,
        simklUser: simklUser,
        activeSyncProvider: syncProvider,
        isLoading: false,
      );

      debugPrint('Auth initialized: Trakt=${traktUser?.username}, Simkl=${simklUser?.username}, Sync=$syncProvider');
    } catch (e) {
      debugPrint('Auth initialization error: $e');
      state = AuthState(isLoading: false, error: e.toString());
    }
  }

  Future<bool> connectTrakt() async {
    if (!TraktAuthService.isConfigured) {
      state = state.copyWith(
        error: 'Trakt API credentials not configured',
        clearError: false,
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await TraktAuthService.authenticate();
      
      if (user != null) {
        state = state.copyWith(
          traktUser: user,
          isLoading: false,
        );
        debugPrint('Trakt connected: ${user.username}');
        return true;
      } else {
        state = state.copyWith(isLoading: false);
        return false;
      }
    } catch (e) {
      debugPrint('Trakt connection error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to connect to Trakt',
      );
      return false;
    }
  }

  Future<void> disconnectTrakt() async {
    state = state.copyWith(isLoading: true);

    try {
      await TraktAuthService.disconnect();
      state = state.copyWith(
        clearTraktUser: true,
        isLoading: false,
      );
      debugPrint('Trakt disconnected');
    } catch (e) {
      debugPrint('Trakt disconnect error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> connectSimkl() async {
    if (!SimklAuthService.isConfigured) {
      state = state.copyWith(
        error: 'Simkl API credentials not configured',
        clearError: false,
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await SimklAuthService.authenticate();
      
      if (user != null) {
        state = state.copyWith(
          simklUser: user,
          isLoading: false,
        );
        debugPrint('Simkl connected: ${user.username}');
        return true;
      } else {
        state = state.copyWith(isLoading: false);
        return false;
      }
    } catch (e) {
      debugPrint('Simkl connection error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to connect to Simkl',
      );
      return false;
    }
  }

  Future<void> disconnectSimkl() async {
    state = state.copyWith(isLoading: true);

    try {
      await SimklAuthService.disconnect();
      state = state.copyWith(
        clearSimklUser: true,
        isLoading: false,
      );
      debugPrint('Simkl disconnected');
    } catch (e) {
      debugPrint('Simkl disconnect error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshTraktProfile() async {
    if (!state.isTraktConnected) return;

    try {
      final user = await TraktAuthService.getUserProfile();
      if (user != null) {
        state = state.copyWith(traktUser: user);
      }
    } catch (e) {
      debugPrint('Trakt profile refresh error: $e');
    }
  }

  Future<void> refreshSimklProfile() async {
    if (!state.isSimklConnected) return;

    try {
      final user = await SimklAuthService.getUserProfile();
      if (user != null) {
        state = state.copyWith(simklUser: user);
      }
    } catch (e) {
      debugPrint('Simkl profile refresh error: $e');
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> setActiveSyncProvider(SyncProvider provider) async {
    if (provider == SyncProvider.trakt && !state.isTraktConnected) return;
    if (provider == SyncProvider.simkl && !state.isSimklConnected) return;

    final providerName = provider == SyncProvider.trakt 
        ? 'trakt' 
        : provider == SyncProvider.simkl 
            ? 'simkl' 
            : 'none';
    
    await SecureStorageService.saveActiveSyncProvider(providerName);
    state = state.copyWith(activeSyncProvider: provider);
    debugPrint('Sync provider set to: $provider');
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
