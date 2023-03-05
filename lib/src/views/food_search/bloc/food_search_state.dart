import 'package:equatable/equatable.dart';
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

class FoodDataFetched extends FoodSearchState {
  final String query;
  final int suppliedPageNumber;
  final int suppliedMaxResults;
  final FoodSearchResults results;
  final bool doesNextPageExist;

  const FoodDataFetched({
    required this.query,
    required this.suppliedPageNumber,
    required this.suppliedMaxResults,
    required this.results,
    required this.doesNextPageExist,
  });

  @override
  List<Object?> get props => [
    query,
    suppliedPageNumber,
    suppliedMaxResults,
    results,
    doesNextPageExist,
  ];
}