import 'package:equatable/equatable.dart';

abstract class DetailedMeetupEvent extends Equatable {
  const DetailedMeetupEvent();

  @override
  List<Object?> get props => [];
}

class FetchAdditionalMeetupData extends DetailedMeetupEvent {
  final String meetupId;
  final String? meetupLocationFsqId;
  final List<String> participantIds;

  const FetchAdditionalMeetupData({
    required this.meetupId,
    required this.participantIds,
    required this.meetupLocationFsqId
  });

  @override
  List<Object?> get props => [meetupId, participantIds, meetupLocationFsqId];
}