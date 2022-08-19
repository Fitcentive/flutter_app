import 'package:flutter_app/src/utils/device_utils.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

class OidcProviderInfo {
  static const String BASE_URL = "http://api.vid.app/api/auth";

  static const String GOOGLE_AUTH_PROVIDER = "GoogleAuth";
  static const String NATIVE_AUTH_PROVIDER = "NativeAuth";
  static String GOOGLE_OIDC_REDIRECT_URI =
    DeviceUtils.isMobileDevice() ? 'io.fitcentive.fitcentive://oidc-callback' : 'http://localhost:5555/auth.html';
  static const String GOOGLE_KEYCLOAK_IDP_HINT = 'google';
  static const String GOOGLE_OIDC_DISCOVER_URI =
      'https://api.vid.app/auth/realms/GoogleAuth/.well-known/openid-configuration';
  static String GOOGLE_OIDC_CLIENT_ID = DeviceUtils.isMobileDevice() ? 'mobileapp' : 'webapp';


  static const String APPLE_AUTH_PROVIDER = "AppleAuth";
  static String APPLE_OIDC_REDIRECT_URI =
  DeviceUtils.isMobileDevice() ? 'io.fitcentive.fitcentive://oidc-callback' : 'http://localhost:5555/auth.html';
  static const String APPLE_KEYCLOAK_IDP_HINT = 'apple';
  static const String APPLE_OIDC_DISCOVER_URI =
      'https://api.vid.app/auth/realms/AppleAuth/.well-known/openid-configuration';
  static String APPLE_OIDC_CLIENT_ID = DeviceUtils.isMobileDevice() ? 'mobileapp' : 'webapp';

  final String authRealm;
  final String discoverUri;
  final String redirectUri;
  final String clientId;
  final String keycloakIdpHint;
  final AuthorizationServiceConfiguration serviceConfiguration;

  const OidcProviderInfo(
      {required this.authRealm,
      required this.discoverUri,
      required this.redirectUri,
      required this.clientId,
      required this.keycloakIdpHint,
      required this.serviceConfiguration});

  factory OidcProviderInfo.googleOidcProviderInfo() => OidcProviderInfo(
        authRealm: GOOGLE_AUTH_PROVIDER,
        discoverUri: GOOGLE_OIDC_DISCOVER_URI,
        redirectUri: GOOGLE_OIDC_REDIRECT_URI,
        clientId: GOOGLE_OIDC_CLIENT_ID,
        keycloakIdpHint: GOOGLE_KEYCLOAK_IDP_HINT,
        serviceConfiguration: const AuthorizationServiceConfiguration(
            authorizationEndpoint: "https://api.vid.app/auth/realms/GoogleAuth/protocol/openid-connect/auth",
            tokenEndpoint: "https://api.vid.app/auth/realms/GoogleAuth/protocol/openid-connect/token"
        )
      );

  factory OidcProviderInfo.appleOidcProviderInfo() => OidcProviderInfo(
      authRealm: APPLE_AUTH_PROVIDER,
      discoverUri: APPLE_OIDC_DISCOVER_URI,
      redirectUri: APPLE_OIDC_REDIRECT_URI,
      clientId: APPLE_OIDC_CLIENT_ID,
      keycloakIdpHint: APPLE_KEYCLOAK_IDP_HINT,
      serviceConfiguration: const AuthorizationServiceConfiguration(
          authorizationEndpoint: "https://api.vid.app/auth/realms/AppleAuth/protocol/openid-connect/auth",
          tokenEndpoint: "https://api.vid.app/auth/realms/AppleAuth/protocol/openid-connect/token"
      )
  );
}
