import 'package:either_dart/either.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result_single_serving.dart';
import 'package:flutter_app/src/models/fatsecret/food_search_results.dart';

abstract class FoodSearchState extends Equatable {
  const FoodSearchState();

  @override
  List<Object?> get props => [];
}

class FoodSearchStateInitial extends FoodSearchState {

  const FoodSearchStateInitial();
}

class FoodDataLoading extends FoodSearchState {

  const FoodDataLoading();
}

class OnlyRecentFoodDataFetched extends FoodSearchState {
  final List<Either<FoodGetResult, FoodGetResultSingleServing>> recentFoods;

  const OnlyRecentFoodDataFetched({
    required this.recentFoods
  });

  @override
  List<Object?> get props => [
    recentFoods,
  ];
}

class FoodDataFetched extends FoodSearchState {
  final String query;
  final int suppliedPageNumber;
  final int suppliedMaxResults;
  final FoodSearchResults results;
  final bool doesNextPageExist;
  final List<Either<FoodGetResult, FoodGetResultSingleServing>> recentFoods;

  const FoodDataFetched({
    required this.query,
    required this.suppliedPageNumber,
    required this.suppliedMaxResults,
    required this.results,
    required this.doesNextPageExist,
    required this.recentFoods,
  });

  @override
  List<Object?> get props => [
    query,
    suppliedPageNumber,
    suppliedMaxResults,
    results,
    doesNextPageExist,
    recentFoods,
  ];
}