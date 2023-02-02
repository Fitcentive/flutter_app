import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/auth/secure_auth_tokens.dart';
import 'package:flutter_app/src/models/meetups/meetup_availability.dart';
import 'package:flutter_app/src/views/detailed_meetup/bloc/detailed_meetup_event.dart';
import 'package:flutter_app/src/views/detailed_meetup/bloc/detailed_meetup_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DetailedMeetupBloc extends Bloc<DetailedMeetupEvent, DetailedMeetupState> {
  final FlutterSecureStorage secureStorage;
  final MeetupRepository meetupRepository;
  final UserRepository userRepository;

  DetailedMeetupBloc({
    required this.secureStorage,
    required this.meetupRepository,
    required this.userRepository
  }): super(const DetailedMeetupStateInitial()) {

    on<FetchAdditionalMeetupData>(_fetchAdditionalMeetupData);
  }

  void _fetchAdditionalMeetupData(FetchAdditionalMeetupData event, Emitter<DetailedMeetupState> emit) async {
    final accessToken = await secureStorage.read(key: SecureAuthTokens.ACCESS_TOKEN_SECURE_STORAGE_KEY);
    emit(const DetailedMeetupStateLoading());

    Map<String, List<MeetupAvailability>> availabilityMap = {};
    final availabilities = await Future.wait(event.participantIds.map((e) =>
        meetupRepository.getMeetupParticipantAvailabilities(event.meetupId, e, accessToken!))
    );

    var i = 0;
    while(i < availabilities.length) {
      availabilityMap[event.participantIds[i]] = availabilities[i];
      i++;
    }

    emit(DetailedMeetupDataFetched(meetupId: event.meetupId, userAvailabilities: availabilityMap));
  }

}