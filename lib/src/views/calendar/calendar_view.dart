import 'dart:math';

import 'package:calendar_view/calendar_view.dart';
import 'package:either_dart/either.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/diary_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/meetup_repository.dart';
import 'package:flutter_app/src/infrastructure/repos/rest/user_repository.dart';
import 'package:flutter_app/src/models/diary/all_diary_entries.dart';
import 'package:flutter_app/src/models/meetups/meetup.dart';
import 'package:flutter_app/src/models/meetups/meetup_decision.dart';
import 'package:flutter_app/src/models/meetups/meetup_location.dart';
import 'package:flutter_app/src/models/meetups/meetup_participant.dart';
import 'package:flutter_app/src/models/public_user_profile.dart';
import 'package:flutter_app/src/utils/constant_utils.dart';
import 'package:flutter_app/src/utils/screen_utils.dart';
import 'package:flutter_app/src/utils/widget_utils.dart';
import 'package:flutter_app/src/views/calendar/bloc/calendar_bloc.dart';
import 'package:flutter_app/src/views/calendar/bloc/calendar_event.dart';
import 'package:flutter_app/src/views/calendar/bloc/calendar_state.dart';
import 'package:flutter_app/src/views/detailed_meetup/detailed_meetup_view.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_bloc.dart';
import 'package:flutter_app/src/views/home/bloc/menu_navigation_event.dart';
import 'package:flutter_app/src/views/home/home_page.dart';
import 'package:flutter_app/src/views/shared_components/diary_card_view.dart';
import 'package:flutter_app/src/views/shared_components/meetup_card/meetup_card_view.dart';
import 'package:flutter_app/src/views/user_chat/user_chat_view.dart';
import 'package:flutter_app/theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class CalendarView extends StatefulWidget {
  final PublicUserProfile currentUserProfile;

  const CalendarView ({Key? key, required this.currentUserProfile}): super(key: key);

  static Widget withBloc(PublicUserProfile currentUserProfile) => MultiBlocProvider(
    providers: [
      BlocProvider<CalendarBloc>(
          create: (context) => CalendarBloc(
            userRepository: RepositoryProvider.of<UserRepository>(context),
            meetupRepository: RepositoryProvider.of<MeetupRepository>(context),
            diaryRepository: RepositoryProvider.of<DiaryRepository>(context),
            secureStorage: RepositoryProvider.of<FlutterSecureStorage>(context),
          )),
    ],
    child: CalendarView(currentUserProfile: currentUserProfile),
  );

  @override
  State createState() {
    return CalendarViewState();
  }
}

class CalendarViewState extends State<CalendarView> {
  static final DateTime minimumDate = DateTime(1970);
  static final DateTime maximumDate = DateTime(2050);

  late CalendarBloc _calendarBloc;
  late MenuNavigationBloc _menuNavigationBloc;

  String selectedCalendarView = "month"; // Options are month, week, day
  DateTime currentSelectedDateTime = DateTime.now();
  DateTime previouslyFetchedDataFor = DateTime.now();
  List<CalendarEventData<Either<Meetup, AllDiaryEntries>>> meetupCalendarEvents = [];
  List<CalendarEventData<Either<Meetup, AllDiaryEntries>>> diaryCalendarEvents = [];

  EventController<Either<Meetup, AllDiaryEntries>> monthCalendarEventController = EventController<Either<Meetup, AllDiaryEntries>>();
  EventController<Either<Meetup, AllDiaryEntries>> weekCalendarEventController = EventController<Either<Meetup, AllDiaryEntries>>();
  EventController<Either<Meetup, AllDiaryEntries>> dayCalendarEventController = EventController<Either<Meetup, AllDiaryEntries>>();

  final HeaderStyle calendarHeaderStyle = const HeaderStyle(
      headerTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
          color: Colors.teal
      ),
      leftIcon: Icon(Icons.chevron_left, color: Colors.white,),
      rightIcon: Icon(Icons.chevron_right, color: Colors.white,)
  );

  @override
  void initState() {
    super.initState();

    _menuNavigationBloc = BlocProvider.of<MenuNavigationBloc>(context);
    _calendarBloc = BlocProvider.of<CalendarBloc>(context);
    _calendarBloc.add(
        FetchCalendarMeetupData(
            userId: widget.currentUserProfile.userId,
            currentSelectedDateTime: currentSelectedDateTime,
        )
    );
  }

  @override
  void dispose() {
    monthCalendarEventController.dispose();
    weekCalendarEventController.dispose();
    dayCalendarEventController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<CalendarBloc, CalendarState>(
        listener: (context, state) {
          if (state is CalendarMeetupUserDataFetched) {

            diaryCalendarEvents = state.allDiaryEntries.entries.entries.where((e) =>
              (e.value.foodEntries.isNotEmpty || e.value.cardioWorkouts.isNotEmpty || e.value.strengthWorkouts.isNotEmpty)
            ).map((e) {
              final currentDate = DateTime.parse(e.key);
              final startTime = DateTime(currentDate.year, currentDate.month, currentDate.day, 21, 0, 0, 0, 0);
              return CalendarEventData(
                  date: currentDate,
                  event: Right<Meetup, AllDiaryEntries>(e.value),
                  color: Colors.tealAccent,
                  title: "Diary",
                  description: "No description",
                  startTime: startTime,
                  endTime: startTime.add(const Duration(hours: 1))
              );
            } ).toList();

            setState(() {
              meetupCalendarEvents = state.meetups
                  .where((m) => m.time != null)
                  .map((m) {
                // Note - we have translate into localtime
                return CalendarEventData(
                  date: m.time!.toLocal(),
                  event: Left<Meetup, AllDiaryEntries>(m),
                  color: Colors.teal,
                  title: m.name ?? "Unnamed meetup",
                  description: m.name ?? "No description",
                  startTime: m.time?.toLocal(),
                  endTime: m.time?.toLocal().add(const Duration(hours: 1))
                );
              })
                  .toList();
              monthCalendarEventController.addAll(meetupCalendarEvents);
              weekCalendarEventController.addAll(meetupCalendarEvents);
              dayCalendarEventController.addAll(meetupCalendarEvents);

              monthCalendarEventController.addAll(diaryCalendarEvents);
              weekCalendarEventController.addAll(diaryCalendarEvents);
              dayCalendarEventController.addAll(diaryCalendarEvents);
            });
          }
        },
        child: BlocBuilder<CalendarBloc, CalendarState>(
          builder: (context, state) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _renderViewSelectButtons(),
                WidgetUtils.spacer(2.5),
                Expanded(child: _renderCalendarView(state)),
              ],
            );
          },
        ),
      ),
    );
  }

  _areDaysTheSame(DateTime d1, DateTime d2) {
    return d1.day == d2.day && d1.month == d2.month && d1.year == d2.year;
  }

  _renderCalendarView(CalendarState state) {
    if (state is CalendarMeetupUserDataFetched) {
      if (selectedCalendarView == "month") {
        return CalendarControllerProvider<Either<Meetup, AllDiaryEntries>>(
          controller: monthCalendarEventController,
          child: MonthView(
            width: min(ScreenUtils.getScreenWidth(context), ConstantUtils.WEB_APP_MAX_WIDTH),
            cellBuilder: (DateTime date, List<CalendarEventData<Either<Meetup, AllDiaryEntries>>> events, bool isToday, bool isInMonth) {
              return FilledCell(
                date: date,
                shouldHighlight: isToday,
                events: events,
                highlightColor: Colors.teal,
                backgroundColor: isInMonth ? ColorConstants.white : ColorConstants.offWhite,
                onTileTap: (event, date) {
                  final eitherEvent = event as CalendarEventData<Either<Meetup, AllDiaryEntries>>;
                  if (eitherEvent.event?.isLeft ?? false) {
                    _showMeetupCardDialog(state, eitherEvent.event!.left);
                  }
                  else {
                    _showDiaryEntriesCardDialog(state, eitherEvent.event!.right, date);
                  }
                },
                dateStringBuilder: ((date, {secondaryDate}) => "${date.day}"),
              );
            },
            controller: monthCalendarEventController,
            minMonth: minimumDate,
            maxMonth: maximumDate,
            initialMonth: currentSelectedDateTime,
            cellAspectRatio: .5,
            onPageChange: (date, pageIndex) {
              setState(() {
                currentSelectedDateTime = date;
              });
            },
            onCellTap: (events, date) {
              setState(() {
                currentSelectedDateTime = date;
              });
            },
            startDay: WeekDays.monday, // To change the first day of the week.
            // This callback will only work if cellBuilder is null.
            onEventTap: (event, date) {
              final eitherEvent = event as Either<Meetup, AllDiaryEntries>;
              if (eitherEvent.isLeft) {
                _showMeetupCardDialog(state, eitherEvent.left);
              }
            },
            onDateLongPress: (date) {
              // show popup menu with options
            },
            dateStringBuilder: ((date, {secondaryDate}) => "${date.day}"),
            headerStringBuilder: ((date, {secondaryDate}) {
              // Note - this is a hack.
              // We actually want a callback whenever the selected date is changed
              // The library doesn't expose that, but this behaves the same way
              // The `date` parameter here is either current time (initially), or start of the month (after selection)
              _fetchMeetupDataForSelectedDateMonth(date);
              return DateFormat("MMM yyyy").format(date).toString();
            }),
            headerStyle: calendarHeaderStyle,
          ),
        );
      }
      else if (selectedCalendarView == "week") {
        return CalendarControllerProvider<Either<Meetup, AllDiaryEntries>>(
            controller: weekCalendarEventController,
            child: WeekView(
              width: min(ScreenUtils.getScreenWidth(context), ConstantUtils.WEB_APP_MAX_WIDTH),
              controller: weekCalendarEventController,
              showLiveTimeLineInAllDays: true, // To display live time line in all pages in week view.
              minDay: minimumDate,
              maxDay: maximumDate,
              initialDay: currentSelectedDateTime,
              heightPerMinute: 1, // height occupied by 1 minute time span.
              eventArranger: const SideEventArranger(), // To define how simultaneous events will be arranged.
              onEventTap: (events, date) {
                final eitherEvent = events.first as CalendarEventData<Either<Meetup, AllDiaryEntries>>;
                if (eitherEvent.event?.isLeft ?? false) {
                  _showMeetupCardDialog(state, eitherEvent.event!.left);
                }
                else {
                  _showDiaryEntriesCardDialog(state, eitherEvent.event!.right, date);
                }
              },
              onDateLongPress: (date) {
                // Show context popup menu
              },
              onDateTap: (date) {
                setState(() {
                  currentSelectedDateTime = date;
                });
              },
              startDay: WeekDays.monday, // To change the first day of the week.
              headerStringBuilder: ((date, {secondaryDate}) {
                // Note - this is a hack.
                // We actually want a callback whenever the selected date is changed
                // The library doesn't expose that, but this behaves the same way
                // The `date` parameter here is either current time (initially), or start of the month (after selection)
                _fetchMeetupDataForSelectedDateMonth(date);
                return DateFormat("MMM yyyy").format(date).toString();
              }),
              headerStyle: calendarHeaderStyle,
              weekDayStringBuilder: (dayIndex) {
                switch (dayIndex) {
                  case 0:
                    return "Mon";
                  case 1:
                    return "Tue";
                  case 2:
                    return "Wed";
                  case 3:
                    return "Thu";
                  case 4:
                    return "Fri";
                  case 5:
                    return "Sat";
                  case 6:
                    return "Sun";
                  default:
                    return "poop";
                }
              },
            )
        );
      }
      else {
        return CalendarControllerProvider<Either<Meetup, AllDiaryEntries>>(
            controller: dayCalendarEventController,
            child: DayView(
              width: min(ScreenUtils.getScreenWidth(context), ConstantUtils.WEB_APP_MAX_WIDTH),
              controller: dayCalendarEventController,
              showVerticalLine: true, // To display live time line in day view.
              showLiveTimeLineInAllDays: true, // To display live time line in all pages in day view.
              minDay: minimumDate,
              maxDay: maximumDate,
              initialDay: currentSelectedDateTime,
              heightPerMinute: 1, // height occupied by 1 minute time span.
              eventArranger: const SideEventArranger(), // To define how simultaneous events will be arranged.
              onEventTap: (events, date) {
                final eitherEvent = events as CalendarEventData<Either<Meetup, AllDiaryEntries>>;
                if (eitherEvent.event?.isLeft ?? false) {
                  _showMeetupCardDialog(state, eitherEvent.event!.left);
                }
                else {
                  _showDiaryEntriesCardDialog(state, eitherEvent.event!.right, date);
                }
              },
              onDateLongPress: (date) => print(date),
              dateStringBuilder: ((date, {secondaryDate}) {
                // Note - this is a hack.
                // We actually want a callback whenever the selected date is changed
                // The library doesn't expose that, but this behaves the same way
                // The `date` parameter here is either current time (initially), or start of the month (after selection)
                currentSelectedDateTime = date;
                _fetchMeetupDataForSelectedDateMonth(date);
                return DateFormat("MMM dd yyyy").format(date).toString();
              }),
              headerStyle: calendarHeaderStyle,
              onPageChange: (date, index) {
                setState(() {
                  currentSelectedDateTime = date;
                });
              },
            )
        );
      }
    }
    else {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

  }

  _fetchMeetupDataForSelectedDateMonth(DateTime selected) {
    if (selected.month != previouslyFetchedDataFor.month || selected.year != previouslyFetchedDataFor.year) {
      _calendarBloc.add(const TrackViewCalendarEvent());
      _calendarBloc.add(
          FetchCalendarMeetupData(
            userId: widget.currentUserProfile.userId,
            currentSelectedDateTime: selected,
          )
      );
      previouslyFetchedDataFor = selected;
    }
    currentSelectedDateTime = selected;
  }

  _showDiaryEntriesCardDialog(CalendarMeetupUserDataFetched state, AllDiaryEntries allDiaryEntries, DateTime date) {
    showDialog(
        context: context,
        builder: (context) {
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: ScreenUtils.getScreenHeight(context) * 0.75,
              ),
              child: DiaryCardView(
                currentUserProfile: widget.currentUserProfile,
                foodDiaryEntries: state.foodDiaryEntries,
                selectedDate: date,
                allDiaryEntries: allDiaryEntries,
                onCardTapped: () {
                  _goToDiaryPage(date);
                },
              ),
            ),
          );
        }
    );
  }

  _goToDiaryPage(DateTime date) {
    Navigator.pop(context); // This is done to dismiss the dialog shown on screen
    _menuNavigationBloc.add(
        MenuItemChosen(
          selectedMenuItem: HomePageState.diary,
          currentUserId: widget.currentUserProfile.userId,
          preSelectedDiaryDateString: DateFormat("yyyy-MM-dd").format(date),
        )
    );
  }

  _showMeetupCardDialog(CalendarMeetupUserDataFetched state, Meetup currentMeetup) {
    showDialog(
        context: context,
        builder: (context) {
          final currentMeetupLocation = state.meetupLocations.firstWhere((element) => element?.id == currentMeetup.locationId);
          final currentMeetupDecisions = state.meetupDecisions[currentMeetup.id]!;
          final currentMeetupParticipants = state.meetupParticipants[currentMeetup.id]!;
          return Center(
            child: MeetupCardView.withBloc(
                currentUserProfile: widget.currentUserProfile,
                meetup: currentMeetup,
                participants: currentMeetupParticipants,
                decisions: currentMeetupDecisions,
                meetupLocation: currentMeetupLocation,
                userIdProfileMap: state.userIdProfileMap,
                onCardTapped: () {
                  _goToEditMeetupView(
                      currentMeetup,
                      currentMeetupLocation,
                      currentMeetupParticipants,
                      currentMeetupDecisions,
                      state.userIdProfileMap.values.where((element) => currentMeetupParticipants.map((e) => e.userId).contains(element.userId)).toList()
                  );
                },
                onChatButtonPressed: (chatRoomId, otherUserProfiles) {
                  Navigator.push(
                      context,
                      UserChatView.route(
                        currentRoomId: chatRoomId,
                        currentUserProfile: widget.currentUserProfile,
                        otherUserProfiles: otherUserProfiles,
                      )
                  );
                }
            ),
          );
        }
    );
  }

  _renderViewSelectButtons() {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        WidgetUtils.spacer(2.5),
        Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.calendar_view_month),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
              ),
              onPressed: () {
                setState(() {
                  selectedCalendarView = "month";
                });
              },
              label: const Text('Month',
                  style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w200)),
            )
        ),
        WidgetUtils.spacer(5),
        Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.calendar_view_week),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
              ),
              onPressed: () {
                setState(() {
                  selectedCalendarView = "week";
                });
              },
              label: const Text('Week',
                  style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w200)),
            )
        ),
        WidgetUtils.spacer(5),
        Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.calendar_view_day),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.teal),
              ),
              onPressed: () {
                setState(() {
                  selectedCalendarView = "day";
                });
              },
              label: const Text('Day',
                  style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w200)),
            )
        ),
        WidgetUtils.spacer(2.5),
      ],
    );
  }

  _goToEditMeetupView(
      Meetup meetup,
      MeetupLocation? meetupLocation,
      List<MeetupParticipant> participants,
      List<MeetupDecision> decisions,
      List<PublicUserProfile> relevantUserProfiles,
      ) {
    Navigator.push(
      context,
      DetailedMeetupView.route(
          meetupId: meetup.id,
          meetup: meetup,
          meetupLocation: meetupLocation,
          participants: participants,
          decisions: decisions,
          userProfiles: relevantUserProfiles,
          currentUserProfile: widget.currentUserProfile
      ),
    ).then((value) {
      _calendarBloc.add(
          FetchCalendarMeetupData(
            userId: widget.currentUserProfile.userId,
            currentSelectedDateTime: currentSelectedDateTime,
          )
      );
    });
  }

}