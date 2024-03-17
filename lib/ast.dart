import 'package:mcfp_compiler/lexer.dart';

abstract class Expr {
  R accept<R>(Visitor<R> visitor);
}

abstract interface class Visitor<R> {
  R visitBinaryExpr(Binary expr);
  R visitGroupingExpr(Grouping expr);
  R visitLiteralExpr(Literal expr);
  R visitUnaryExpr(Unary expr);
}

class Binary extends Expr {
  final Expr left;
  final Token operator;
  final Expr right;

  Binary(this.left, this.operator, this.right);

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitBinaryExpr(this);
  }
}

class Grouping extends Expr {
  final Expr expression;

  Grouping(this.expression);

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitGroupingExpr(this);
  }
}

class Literal extends Expr {
  final Object? value;

  Literal(this.value);

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitLiteralExpr(this);
  }
}

class Unary extends Expr {
  final Token operator;
  final Expr right;

  Unary(this.operator, this.right);

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitUnaryExpr(this);
  }
}