import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_last_seen.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class UserLastSeen extends Equatable {
  final String roomId;
  final String userId;
  final DateTime lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;


  const UserLastSeen(this.roomId, this.userId, this.lastSeen, this.createdAt, this.updatedAt);

  @override
  List<Object> get props => [roomId, userId, lastSeen, createdAt, updatedAt];

  factory UserLastSeen.fromJson(Map<String, dynamic> json) => _$UserLastSeenFromJson(json);

  Map<String, dynamic> toJson() => _$UserLastSeenToJson(this);
}