import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/views/add_to_diary/bloc/add_to_diary_event.dart';
import 'package:flutter_app/src/views/add_to_diary/bloc/add_to_diary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AddToDiaryBloc extends Bloc<AddToDiaryEvent, AddToDiaryState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;

  AddToDiaryBloc({
    required this.diaryRepository,
    required this.secureStorage,
  }) : super(const AddToDiaryStateInitial()) {

  }

}