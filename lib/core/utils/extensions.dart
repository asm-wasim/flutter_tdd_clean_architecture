import 'package:dartz/dartz.dart';

extension EitherX<L, R> on Either<L, R> {
  L getLeft() => (this as Left).value;

  R getRight() => (this as Right).value;
}
