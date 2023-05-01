import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';

abstract class FoodSearchEvent extends Equatable {
  const FoodSearchEvent();

  @override
  List<Object?> get props => [];
}

class ClearFoodSearchQuery extends FoodSearchEvent {

  const ClearFoodSearchQuery();

  @override
  List<Object?> get props => [];

}

class FetchRecentFoodSearchInfo extends FoodSearchEvent {
  final String currentUserId;

  const FetchRecentFoodSearchInfo({
    required this.currentUserId
  });

  @override
  List<Object?> get props => [currentUserId];
}

class FetchFoodSearchInfo extends FoodSearchEvent {
  final String currentUserId;
  final String query;
  final int pageNumber;
  final int maxResults;

  const FetchFoodSearchInfo({
    required this.currentUserId,
    required this.query,
    this.pageNumber = DiaryRepository.DEFAULT_SEARCH_FOOD_RESULTS_PAGE,
    this.maxResults = DiaryRepository.DEFAULT_MAX_SEARCH_FOOD_RESULTS,
  });

  @override
  List<Object?> get props => [
    currentUserId,
    query,
    pageNumber,
    maxResults,
  ];
}