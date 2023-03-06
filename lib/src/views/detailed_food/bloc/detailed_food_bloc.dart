import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/views/detailed_food/bloc/detailed_food_event.dart';
import 'package:flutter_app/src/views/detailed_food/bloc/detailed_food_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DetailedFoodBloc extends Bloc<DetailedFoodEvent, DetailedFoodState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;

  DetailedFoodBloc({
    required this.diaryRepository,
    required this.secureStorage,
  }) : super(const DetailedFoodStateInitial()) {

  }

}