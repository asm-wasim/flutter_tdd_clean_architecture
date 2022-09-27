import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/utils/input_converter.dart';
import '../../domain/entities/number_trivia.dart';
import '../../domain/usecases/get_concrete_number_trivia.dart';
import '../../domain/usecases/get_random_number_trivia.dart';

part 'number_trivia_event.dart';

part 'number_trivia_state.dart';

const String serverFailureMessage = 'Server Failure';
const String cacheFailureMessage = 'Cache Failure';
const String invalidInputFailureMessage =
    'Invalid Input - The number must be a positive integer or zero.';

class NumberTriviaBloc extends Bloc<NumberTriviaEvent, NumberTriviaState> {
  final GetConcreteNumberTrivia getConcreteNumberTrivia;
  final GetRandomNumberTrivia getRandomNumberTrivia;
  final InputConverter inputConverter;

  NumberTriviaBloc({
    required GetConcreteNumberTrivia concrete,
    required GetRandomNumberTrivia random,
    required InputConverter converter,
  })  : getConcreteNumberTrivia = concrete,
        getRandomNumberTrivia = random,
        inputConverter = converter,
        super(Empty()) {
    on<NumberTriviaEvent>(_getNumberTrivia);
  }

  NumberTriviaState get initialState => Empty();

  void _getNumberTrivia(
    NumberTriviaEvent event,
    Emitter<NumberTriviaState> emit,
  ) async {
    emit(Loading());
    if (event is GetTriviaForConcreteNumber) {
      final inputEither =
          inputConverter.stringToUnsignedInteger(event.numberString);

      if (inputEither.isLeft()) {
        emit(const Error(message: invalidInputFailureMessage));
      } else {
        final failureOrTrivia = await getConcreteNumberTrivia(
          Params(number: inputEither.getRight()),
        );
        if (failureOrTrivia.isLeft()) {
          emit(Error(
            message: _mapFailureToMessage(failureOrTrivia.getLeft()),
          ));
        } else {
          emit(Loaded(trivia: failureOrTrivia.getRight()));
        }
      }
    } else if (event is GetTriviaForRandomNumber) {
      final failureOrTrivia = await getRandomNumberTrivia(NoParams());
      _getFailureOrTrivia(failureOrTrivia, emit);
    } else {
      emit(const Error(message: 'Unknown event error'));
    }
  }

  void _getFailureOrTrivia(
    Either<Failure, NumberTrivia> failureOrTrivia,
    Emitter<NumberTriviaState> emit,
  ) {
    emit(failureOrTrivia.fold(
      (failure) => Error(message: _mapFailureToMessage(failure)),
      (trivia) => Loaded(trivia: trivia),
    ));
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case ServerFailure:
        return serverFailureMessage;
      case CacheFailure:
        return cacheFailureMessage;
      default:
        return 'Unexpected Error';
    }
  }
}
