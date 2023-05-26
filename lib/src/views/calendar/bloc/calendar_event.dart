import 'package:equatable/equatable.dart';

abstract class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => [];
}

class FetchCalendarMeetupData extends CalendarEvent {
  final String userId;
  final DateTime currentSelectedDateTime;

  const FetchCalendarMeetupData({
    required this.userId,
    required this.currentSelectedDateTime,
  });

  @override
  List<Object?> get props => [userId, currentSelectedDateTime];
}
