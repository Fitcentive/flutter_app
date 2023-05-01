import 'package:either_dart/src/either.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result.dart';
import 'package:flutter_app/src/models/fatsecret/food_get_result_single_serving.dart';
import 'package:flutter_app/src/models/fatsecret/food_results.dart';
import 'package:flutter_app/src/models/fatsecret/food_search_results.dart';
import 'package:flutter_app/src/views/food_search/bloc/food_search_event.dart';
import 'package:flutter_app/src/views/food_search/bloc/food_search_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FoodSearchBloc extends Bloc<FoodSearchEvent, FoodSearchState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;

  FoodSearchBloc({
    required this.diaryRepository,
    required this.secureStorage,
  }) : super(const FoodSearchStateInitial()) {
    on<FetchFoodSearchInfo>(_fetchFoodSearchInfo);
    on<FetchRecentFoodSearchInfo>(_fetchRecentFoodSearchInfo);
    on<ClearFoodSearchQuery>(_clearFoodSearchQuery);
  }

  void _fetchRecentFoodSearchInfo(FetchRecentFoodSearchInfo event, Emitter<FoodSearchState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);

    final recentFoodIds = await diaryRepository.getUserMostRecentlyViewedFoodIds(event.currentUserId, accessToken!);
    final List<Either<FoodGetResult, FoodGetResultSingleServing>> recentFoods = await Future.wait(recentFoodIds.map((id) => diaryRepository.getFoodById(id, accessToken)));
    emit(
        OnlyRecentFoodDataFetched(
          recentFoods: recentFoods
        )
    );
  }

  void _clearFoodSearchQuery(ClearFoodSearchQuery event, Emitter<FoodSearchState> emit) async {
    final currentState = state;
    if (currentState is FoodDataFetched) {
      emit(FoodDataFetched(
          query: "",
          suppliedMaxResults: 0,
          suppliedPageNumber: 0,
          results: FoodSearchResults.empty(),
          recentFoods: currentState.recentFoods,
          doesNextPageExist: false
      ));
    }
  }

  // When search query doesnt change, then we append
  // Otherwise we refetch
  void _fetchFoodSearchInfo(FetchFoodSearchInfo event, Emitter<FoodSearchState> emit) async {
    final currentState = state;
    if (currentState is OnlyRecentFoodDataFetched) {
      emit(const FoodDataLoading());
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final results = await diaryRepository.searchForFoods(event.query, accessToken!, pageNumber: event.pageNumber, maxResults: event.maxResults);

      emit(FoodDataFetched(
          query: event.query,
          suppliedMaxResults: event.maxResults,
          suppliedPageNumber: event.pageNumber,
          results: results,
          recentFoods: currentState.recentFoods,
          doesNextPageExist: results.foods.food.length == DiaryRepository.DEFAULT_MAX_SEARCH_FOOD_RESULTS
      ));
    }
    else if (currentState is FoodDataFetched) {
      final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
      final results = await diaryRepository.searchForFoods(event.query, accessToken!, pageNumber: event.pageNumber, maxResults: event.maxResults);

      // Search query hasn't changed, we append results
      if (currentState.query == event.query) {
        emit(
          FoodDataFetched(
            query: event.query,
            suppliedMaxResults: event.maxResults,
            suppliedPageNumber: event.pageNumber,
            results: FoodSearchResults(
                FoodResults(
                    [...currentState.results.foods.food, ...results.foods.food],
                    (currentState.results.foods.food.length + results.foods.food.length).toString(),
                    results.foods.page_number,
                    results.foods.total_results
                )
            ),
            recentFoods: currentState.recentFoods,
            doesNextPageExist: results.foods.food.length == DiaryRepository.DEFAULT_MAX_SEARCH_FOOD_RESULTS
          )
        );
      }
      else {
        emit(
            FoodDataFetched(
              query: event.query,
              suppliedMaxResults: event.maxResults,
              suppliedPageNumber: event.pageNumber,
              results: results,
              recentFoods: currentState.recentFoods,
              doesNextPageExist: results.foods.food.length == DiaryRepository.DEFAULT_MAX_SEARCH_FOOD_RESULTS
            )
        );
      }
    }
  }

}