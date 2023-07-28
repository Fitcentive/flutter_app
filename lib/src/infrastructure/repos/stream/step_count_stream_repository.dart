import 'dart:async';

/// For more information on streaming repositories, refer to
/// https://bloclibrary.dev/#/architecture?id=connecting-blocs-through-domain
class StepCountStreamRepository {

  final _controller = StreamController<int>.broadcast();

  Stream<int> get updatedStepCount async* {
    yield* _controller.stream;
  }

  void newStepCount(int count) => _controller.add(count);
}