import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/views/diary/bloc/diary_event.dart';
import 'package:flutter_app/src/views/diary/bloc/diary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DiaryBloc extends Bloc<DiaryEvent, DiaryState> {
  final FlutterSecureStorage secureStorage;
  final DiaryRepository diaryRepository;

  DiaryBloc({
    required this.diaryRepository,
    required this.secureStorage,
  }) : super(const DiaryStateInitial()) {
    on<FetchDiaryInfo>(_fetchDiaryInfo);
  }

  // todo - fetch actual info
  void _fetchDiaryInfo(FetchDiaryInfo event, Emitter<DiaryState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    emit(DiaryDataFetched());
  }

}