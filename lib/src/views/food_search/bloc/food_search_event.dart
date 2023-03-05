import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';

abstract class FoodSearchEvent extends Equatable {
  const FoodSearchEvent();

  @override
  List<Object?> get props => [];
}

class FetchFoodSearchInfo extends FoodSearchEvent {
  final String query;
  final int pageNumber;
  final int maxResults;

  const FetchFoodSearchInfo({
    required this.query,
    this.pageNumber = DiaryRepository.DEFAULT_SEARCH_FOOD_RESULTS_PAGE,
    this.maxResults = DiaryRepository.DEFAULT_MAX_SEARCH_FOOD_RESULTS,
  });

  @override
  List<Object?> get props => [
    query,
    pageNumber,
    maxResults,
  ];
}