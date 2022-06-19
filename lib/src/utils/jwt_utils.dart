import 'package:jwt_decoder/jwt_decoder.dart';

class JwtUtils {
  static const _userIdKey = 'user_id';
  static const _authRealmKey = 'claims';

  static String? getUserIdFromJwtToken(String token) {
    final decodedTokenMap = JwtDecoder.decode(token);
    return decodedTokenMap[_userIdKey];
  }

  static String? getAuthRealmFromJwtToken(String token) {
    final decodedTokenMap = JwtDecoder.decode(token);
    return decodedTokenMap[_authRealmKey];
  }
}
