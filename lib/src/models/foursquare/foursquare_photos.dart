import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'foursquare_photos.g.dart';

@JsonSerializable()
class FourSquarePhoto extends Equatable {
  final String id;
  final String url;
  final int width;
  final int height;
  final DateTime createdAt;

  const FourSquarePhoto(this.id, this.url, this.width, this.height, this.createdAt);

  factory FourSquarePhoto.fromJson(Map<String, dynamic> json) => _$FourSquarePhotoFromJson(json);

  Map<String, dynamic> toJson() => _$FourSquarePhotoToJson(this);

  @override
  List<Object?> get props => [
    id,
    url,
    width,
    height,
    createdAt,
  ];
}