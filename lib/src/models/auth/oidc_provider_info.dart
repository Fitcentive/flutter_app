class OidcProviderInfo {
  static const String BASE_URL = "http://api.vid.app/api/auth";
  static const String GOOGLE_AUTH_PROVIDER = "GoogleAuth";
  static const String NATIVE_AUTH_PROVIDER = "NativeAuth";
  static const String GOOGLE_OIDC_REDIRECT_URI = 'io.fitcentive.fitcentive://oidc-callback';
  static const String GOOGLE_KEYCLOAK_IDP_HINT = 'google';
  static const String GOOGLE_OIDC_DISCOVER_URI =
      'http://api.vid.app/auth/realms/GoogleAuth/.well-known/openid-configuration';
  static const String GOOGLE_OIDC_CLIENT_ID = 'mobileapp';

  final String authRealm;
  final String discoverUri;
  final String redirectUri;
  final String clientId;
  final String keycloakIdpHint;

  const OidcProviderInfo(
      {required this.authRealm,
      required this.discoverUri,
      required this.redirectUri,
      required this.clientId,
      required this.keycloakIdpHint});

  factory OidcProviderInfo.googleOidcProviderInfo() => const OidcProviderInfo(
        authRealm: GOOGLE_AUTH_PROVIDER,
        discoverUri: GOOGLE_OIDC_DISCOVER_URI,
        redirectUri: GOOGLE_OIDC_REDIRECT_URI,
        clientId: GOOGLE_OIDC_CLIENT_ID,
        keycloakIdpHint: GOOGLE_KEYCLOAK_IDP_HINT,
      );
}