import 'package:equatable/equatable.dart';

abstract class DetailedFoodEvent extends Equatable {
  const DetailedFoodEvent();

  @override
  List<Object?> get props => [];
}

class FetchDetailedFoodInfo extends DetailedFoodEvent {
  final String currentUserId;
  final String foodId;

  const FetchDetailedFoodInfo({
    required this.currentUserId,
    required this.foodId,
  });

  @override
  List<Object?> get props => [
    foodId,
    currentUserId,
  ];
}