import 'package:flutter/foundation.dart';

class OAuthHelper {
  static const String customScheme = 'com.stream.app';
  static const String callbackPath = 'callback';
  static const int localhostPort = 43823;

  static String getRedirectUri({String? webDomain}) {
    if (kIsWeb) {
      if (webDomain != null && webDomain.isNotEmpty) {
        return '$webDomain/callback.html';
      }
      return 'http://localhost:8080/callback.html';
    }

    if (_isWindowsOrLinux) {
      return 'http://localhost:$localhostPort/$callbackPath';
    }

    return '$customScheme://$callbackPath';
  }

  static String getCallbackScheme() {
    if (kIsWeb) {
      return 'http';
    }

    if (_isWindowsOrLinux) {
      return 'http://localhost:$localhostPort';
    }

    return customScheme;
  }

  static bool get _isWindowsOrLinux {
    return defaultTargetPlatform == TargetPlatform.windows ||
           defaultTargetPlatform == TargetPlatform.linux;
  }

  static bool get _isDesktop {
    return defaultTargetPlatform == TargetPlatform.windows ||
           defaultTargetPlatform == TargetPlatform.linux ||
           defaultTargetPlatform == TargetPlatform.macOS;
  }

  static bool get isMobile {
    return defaultTargetPlatform == TargetPlatform.android ||
           defaultTargetPlatform == TargetPlatform.iOS;
  }

  static bool get isDesktop => _isDesktop;

  static String get platformName {
    if (kIsWeb) return 'Web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'Android';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.macOS:
        return 'macOS';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      default:
        return 'Unknown';
    }
  }

  static Uri buildAuthUrl({
    required String authorizeEndpoint,
    required String clientId,
    required String redirectUri,
    String responseType = 'code',
    String? state,
    List<String>? scopes,
  }) {
    final queryParams = <String, String>{
      'response_type': responseType,
      'client_id': clientId,
      'redirect_uri': redirectUri,
    };
    
    if (state != null) {
      queryParams['state'] = state;
    }
    
    if (scopes != null && scopes.isNotEmpty) {
      queryParams['scope'] = scopes.join(' ');
    }
    
    return Uri.parse(authorizeEndpoint).replace(queryParameters: queryParams);
  }

  static String generateState() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    return 'stream_${random.substring(random.length - 8)}';
  }

  static void logOAuthInfo({
    required String service,
    required String action,
    String? details,
  }) {
    final platform = platformName;
    debugPrint('OAuth [$service] on $platform: $action${details != null ? ' - $details' : ''}');
  }
}
