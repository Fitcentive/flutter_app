import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_event.dart';
import 'package:flutter_app/src/views/create_new_meetup/bloc/create_new_meetup_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CreateNewMeetupBloc extends Bloc<CreateNewMeetupEvent, CreateNewMeetupState> {
  final FlutterSecureStorage secureStorage;
  final MeetupRepository meetupRepository;

  CreateNewMeetupBloc({
    required this.secureStorage,
    required this.meetupRepository
  }) : super(const NewMeetupStateInitial()) {
    on<NewMeetupChanged>(_newMeetupChanged);
  }

  void _newMeetupChanged(
      NewMeetupChanged event,
      Emitter<CreateNewMeetupState> emit
      ) async {

  }
}