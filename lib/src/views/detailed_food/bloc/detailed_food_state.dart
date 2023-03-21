import 'package:either_dart/either.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result_single_serving.dart';

abstract class DetailedFoodState extends Equatable {
  const DetailedFoodState();

  @override
  List<Object?> get props => [];
}

class DetailedFoodStateInitial extends DetailedFoodState {

  const DetailedFoodStateInitial();
}

class DetailedFoodInfoLoading extends DetailedFoodState {

  const DetailedFoodInfoLoading();

  @override
  List<Object?> get props => [];
}

class DetailedFoodDataFetched extends DetailedFoodState {
  final String foodId;
  final Either<FoodGetResult, FoodGetResultSingleServing> result;

  const DetailedFoodDataFetched({
    required this.foodId,
    required this.result,
  });

  @override
  List<Object?> get props => [
    foodId,
    result,
  ];
}