import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:stream/core/services/secure_storage_service.dart';
import 'package:stream/core/services/oauth_helper.dart';

class SimklUser {
  final String username;
  final String? name;
  final String? avatar;
  final bool isVip;

  SimklUser({
    required this.username,
    this.name,
    this.avatar,
    this.isVip = false,
  });

  factory SimklUser.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? json;
    return SimklUser(
      username: user['name'] ?? '',
      name: user['name'],
      avatar: user['avatar'],
      isVip: user['account']?['type'] == 'vip',
    );
  }
}

class SimklAuthService {
  static final Dio _dio = Dio();

  static const String _authorizeUrl = 'https://simkl.com/oauth/authorize';
  static const String _tokenUrl = 'https://api.simkl.com/oauth/token';
  static const String _userUrl = 'https://api.simkl.com/users/settings';

  static String get _clientId => dotenv.env['SIMKL_CLIENT_ID'] ?? '';
  static String get _clientSecret => dotenv.env['SIMKL_CLIENT_SECRET'] ?? '';
  static String get _redirectUri => OAuthHelper.getRedirectUri();

  static bool get isConfigured => _clientId.isNotEmpty && !_clientId.startsWith('your_');

  static Future<SimklUser?> authenticate() async {
    if (!isConfigured) {
      debugPrint('Simkl: Client ID not configured');
      return null;
    }

    try {
      final state = OAuthHelper.generateState();

      final authUrl = OAuthHelper.buildAuthUrl(
        authorizeEndpoint: _authorizeUrl,
        clientId: _clientId,
        redirectUri: _redirectUri,
        responseType: 'code',
        state: state,
      );

      debugPrint('Simkl: Opening auth URL in system browser');
      debugPrint('Simkl: Platform: ${OAuthHelper.platformName}');
      debugPrint('Simkl: Redirect URI: $_redirectUri');

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: OAuthHelper.getCallbackScheme(),
        options: const FlutterWebAuth2Options(
          preferEphemeral: true,
        ),
      );

      debugPrint('Simkl: Callback received');

      final uri = Uri.parse(result);
      final code = uri.queryParameters['code'];
      final returnedState = uri.queryParameters['state'];

      if (returnedState != state) {
        debugPrint('Simkl: State mismatch - possible CSRF attack');
        return null;
      }

      if (code == null) {
        debugPrint('Simkl: No authorization code in callback');
        return null;
      }

      final accessToken = await _exchangeCodeForToken(code);
      if (accessToken == null) return null;

      await SecureStorageService.saveSimklAccessToken(accessToken);

      final user = await getUserProfile();
      if (user != null) {
        await SecureStorageService.saveSimklUsername(user.username);
      }

      return user;
    } catch (e) {
      debugPrint('Simkl: Authentication error: $e');
      return null;
    }
  }

  static Future<String?> _exchangeCodeForToken(String code) async {
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

      debugPrint('Simkl: Token exchange successful');
      return response.data['access_token'];
    } catch (e) {
      debugPrint('Simkl: Token exchange error: $e');
      return null;
    }
  }

  static Future<SimklUser?> getUserProfile() async {
    try {
      final accessToken = await SecureStorageService.getSimklAccessToken();
      if (accessToken == null) return null;

      final response = await _dio.get(
        _userUrl,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'simkl-api-key': _clientId,
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      return SimklUser.fromJson(response.data);
    } catch (e) {
      debugPrint('Simkl: Get user profile error: $e');
      return null;
    }
  }

  static Future<void> disconnect() async {
    await SecureStorageService.clearSimklTokens();
    debugPrint('Simkl: Disconnected');
  }

  static Future<bool> isConnected() async {
    final token = await SecureStorageService.getSimklAccessToken();
    return token != null;
  }

  static Future<String?> getCachedUsername() async {
    return await SecureStorageService.getSimklUsername();
  }

  static Future<String?> getValidAccessToken() async {
    return await SecureStorageService.getSimklAccessToken();
  }
}
