// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detailed_meetup.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DetailedMeetup _$DetailedMeetupFromJson(Map<String, dynamic> json) =>
    DetailedMeetup(
      Meetup.fromJson(json['meetup'] as Map<String, dynamic>),
      json['location'] == null
          ? null
          : MeetupLocation.fromJson(json['location'] as Map<String, dynamic>),
      (json['participants'] as List<dynamic>)
          .map((e) => MeetupParticipant.fromJson(e as Map<String, dynamic>))
          .toList(),
      (json['decisions'] as List<dynamic>)
          .map((e) => MeetupDecision.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DetailedMeetupToJson(DetailedMeetup instance) =>
    <String, dynamic>{
      'meetup': instance.meetup,
      'location': instance.location,
      'participants': instance.participants,
      'decisions': instance.decisions,
    };
