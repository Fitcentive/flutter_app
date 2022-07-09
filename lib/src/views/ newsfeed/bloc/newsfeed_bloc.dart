import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/repos/rest/social_media_repository.dart';
import 'package:flutter_app/src/views/%20newsfeed/bloc/newsfeed_event.dart';
import 'package:flutter_app/src/views/%20newsfeed/bloc/newsfeed_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class NewsFeedBloc extends Bloc<NewsFeedEvent, NewsFeedState> {
  final SocialMediaRepository socialMediaRepository;
  final FlutterSecureStorage secureStorage;

  NewsFeedBloc({
    required this.socialMediaRepository,
    required this.secureStorage
  }): super(const NewsFeedStateInitial()) {
    on<NewsFeedFetchRequested>(_newsFeedFetchRequested);
  }

  void _newsFeedFetchRequested(NewsFeedFetchRequested event, Emitter<NewsFeedState> emit) async {
    emit(const NewsFeedDataLoading());
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    final posts = await socialMediaRepository.getNewsfeedForUser(event.user.user.id, accessToken!);
    emit(NewsFeedDataReady(user: event.user, posts: posts));
  }
}