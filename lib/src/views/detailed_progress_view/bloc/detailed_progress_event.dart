import 'package:equatable/equatable.dart';
import 'package:flutter_app/src/models/awards/award_categories.dart';

abstract class DetailedProgressEvent extends Equatable {
  const DetailedProgressEvent();

  @override
  List<Object?> get props => [];
}

class FetchDataForMetricCategory extends DetailedProgressEvent {
  final String userId;
  final AwardCategory category;
  final String from;
  final String to;


  const FetchDataForMetricCategory({
    required this.userId,
    required this.category,
    required this.from,
    required this.to
  });

  @override
  List<Object> get props => [
    userId,
    category,
    from,
    to
  ];
}
