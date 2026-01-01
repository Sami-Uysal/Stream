import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:stream/core/services/secure_storage_service.dart';
import 'package:stream/core/services/oauth_helper.dart';

class TraktUser {
  final String username;
  final String? name;
  final String? avatar;
  final bool isVip;

  TraktUser({
    required this.username,
    this.name,
    this.avatar,
    this.isVip = false,
  });

  factory TraktUser.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? json;
    return TraktUser(
      username: user['username'] ?? '',
      name: user['name'],
      avatar: user['images']?['avatar']?['full'],
      isVip: user['vip'] ?? false,
    );
  }
}

class TraktAuthService {
  static final Dio _dio = Dio();

  static const String _authorizeUrl = 'https://trakt.tv/oauth/authorize';
  static const String _tokenUrl = 'https://api.trakt.tv/oauth/token';
  static const String _revokeUrl = 'https://api.trakt.tv/oauth/revoke';
  static const String _userUrl = 'https://api.trakt.tv/users/me';

  static String get _clientId => dotenv.env['TRAKT_CLIENT_ID'] ?? '';
  static String get _clientSecret => dotenv.env['TRAKT_CLIENT_SECRET'] ?? '';

  static String get _redirectUri {
    if (kIsWeb) {
      final webDomain = dotenv.env['OAUTH_WEB_DOMAIN'];
      return OAuthHelper.getRedirectUri(webDomain: webDomain);
    }
    return OAuthHelper.getRedirectUri();
  }

  static bool get isConfigured => _clientId.isNotEmpty && !_clientId.startsWith('your_');

  static Future<TraktUser?> authenticate() async {
    if (!isConfigured) {
      debugPrint('Trakt: Client ID not configured');
      return null;
    }

    try {
      final state = OAuthHelper.generateState();
      final authUrl = OAuthHelper.buildAuthUrl(
        authorizeEndpoint: _authorizeUrl,
        clientId: _clientId,
        redirectUri: _redirectUri,
        state: state,
      );

      OAuthHelper.logOAuthInfo(
        service: 'Trakt',
        action: 'Opening auth URL',
        details: authUrl.toString(),
      );

      final callbackScheme = OAuthHelper.getCallbackScheme();
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: callbackScheme,
        options: const FlutterWebAuth2Options(
          preferEphemeral: true,
        ),
      );

      OAuthHelper.logOAuthInfo(
        service: 'Trakt',
        action: 'Callback received',
        details: result,
      );

      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];

      if (code == null) {
        debugPrint('Trakt: No authorization code in callback');
        return null;
      }

      final tokens = await _exchangeCodeForToken(code);
      if (tokens == null) return null;

      await SecureStorageService.saveTraktAccessToken(tokens['access_token']);
      await SecureStorageService.saveTraktRefreshToken(tokens['refresh_token']);

      final expiresIn = tokens['expires_in'] as int;
      final expiresAt = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + expiresIn;
      await SecureStorageService.saveTraktExpiresAt(expiresAt);

      final user = await getUserProfile();
      if (user != null) {
        await SecureStorageService.saveTraktUsername(user.username);
      }

      return user;
    } catch (e) {
      debugPrint('Trakt: Authentication error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> _exchangeCodeForToken(String code) async {
    try {
      final response = await _dio.post(
        _tokenUrl,
        data: {
          'code': code,
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'redirect_uri': _redirectUri,
          'grant_type': 'authorization_code',
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      debugPrint('Trakt: Token exchange successful');
      return response.data;
    } catch (e) {
      debugPrint('Trakt: Token exchange error: $e');
      return null;
    }
  }

  static Future<bool> refreshToken() async {
    try {
      final refreshToken = await SecureStorageService.getTraktRefreshToken();
      if (refreshToken == null) {
        debugPrint('Trakt: No refresh token available');
        return false;
      }

      final response = await _dio.post(
        _tokenUrl,
        data: {
          'refresh_token': refreshToken,
          'client_id': _clientId,
          'client_secret': _clientSecret,
          'redirect_uri': _redirectUri,
          'grant_type': 'refresh_token',
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final data = response.data;
      
      // Save new tokens
      await SecureStorageService.saveTraktAccessToken(data['access_token']);
      await SecureStorageService.saveTraktRefreshToken(data['refresh_token']);
      
      final expiresIn = data['expires_in'] as int;
      final expiresAt = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + expiresIn;
      await SecureStorageService.saveTraktExpiresAt(expiresAt);

      debugPrint('Trakt: Token refresh successful');
      return true;
    } catch (e) {
      debugPrint('Trakt: Token refresh error: $e');
      return false;
    }
  }

  static Future<String?> getValidAccessToken() async {
    final accessToken = await SecureStorageService.getTraktAccessToken();
    if (accessToken == null) return null;

    if (await SecureStorageService.isTraktTokenExpired()) {
      debugPrint('Trakt: Token expired, attempting refresh');
      final refreshed = await refreshToken();
      if (!refreshed) {
        await SecureStorageService.clearTraktTokens();
        return null;
      }
      return await SecureStorageService.getTraktAccessToken();
    }

    return accessToken;
  }

  static Future<TraktUser?> getUserProfile() async {
    try {
      final accessToken = await getValidAccessToken();
      if (accessToken == null) return null;

      final response = await _dio.get(
        _userUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'trakt-api-version': '2',
            'trakt-api-key': _clientId,
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      return TraktUser.fromJson(response.data);
    } catch (e) {
      debugPrint('Trakt: Get user profile error: $e');
      return null;
    }
  }

  static Future<void> disconnect() async {
    try {
      final accessToken = await SecureStorageService.getTraktAccessToken();
      
      if (accessToken != null) {
        await _dio.post(
          _revokeUrl,
          data: {
            'token': accessToken,
            'client_id': _clientId,
            'client_secret': _clientSecret,
          },
          options: Options(
            headers: {'Content-Type': 'application/json'},
          ),
        );
        debugPrint('Trakt: Token revoked');
      }
    } catch (e) {
      debugPrint('Trakt: Revoke error (continuing anyway): $e');
    }

    await SecureStorageService.clearTraktTokens();
    debugPrint('Trakt: Disconnected');
  }

  static Future<bool> isConnected() async {
    final token = await SecureStorageService.getTraktAccessToken();
    return token != null;
  }

  static Future<String?> getCachedUsername() async {
    return await SecureStorageService.getTraktUsername();
  }
}
