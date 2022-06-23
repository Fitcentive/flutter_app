import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'auth_tokens.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class AuthTokens extends Equatable {

  @JsonKey(required: true)
  final String accessToken;

  @JsonKey(required: true)
  final String refreshToken;

  final int expiresIn;
  final int refreshExpiresIn;
  final String tokenType;
  final String scope;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => _$AuthTokensFromJson(json);

  Map<String, dynamic> toJson() => _$AuthTokensToJson(this);

  const AuthTokens(
      this.accessToken,
      this.refreshToken,
      this.expiresIn,
      this.refreshExpiresIn,
      this.tokenType,
      this.scope,
      );

  @override
  List<Object> get props => [
        accessToken,
        expiresIn,
        refreshExpiresIn,
        refreshToken,
        tokenType,
        scope
      ];
}
