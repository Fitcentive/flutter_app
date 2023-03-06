import 'package:equatable/equatable.dart';

abstract class DetailedFoodState extends Equatable {
  const DetailedFoodState();

  @override
  List<Object?> get props => [];
}

class DetailedFoodStateInitial extends DetailedFoodState {

  const DetailedFoodStateInitial();
}
