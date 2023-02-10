import 'package:equatable/equatable.dart';

abstract class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => [];
}

class FetchCalendarMeetupData extends CalendarEvent {
  final String userId;
  final int year;
  final int month;

  const FetchCalendarMeetupData({
    required this.userId,
    required this.year,
    required this.month,
  });

  @override
  List<Object?> get props => [userId, year, month];
}
