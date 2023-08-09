import 'package:equatable/equatable.dart';

abstract class AddFoodToDiaryState extends Equatable {
  const AddFoodToDiaryState();

  @override
  List<Object?> get props => [];
}

class AddToFoodDiaryStateInitial extends AddFoodToDiaryState {

  const AddToFoodDiaryStateInitial();
}

class FoodDiaryEntryBeingAdded extends AddFoodToDiaryState {

  const FoodDiaryEntryBeingAdded();
}

class FoodDiaryEntryAdded extends AddFoodToDiaryState {

  const FoodDiaryEntryAdded();
}
