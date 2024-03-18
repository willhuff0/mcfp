import 'package:mcfp_compiler/ast_expr.dart';

abstract class Stmt {
  R accept<R>(Visitor<R> visitor);
}

abstract interface class Visitor<R> {
  R visitExpressionStmt(Expression stmt);
  R visitPrintStmt(Print stmt);
}

class Expression extends Stmt {
  final Expr expression;

  Expression(this.expression);

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitExpressionStmt(this);
  }
}

class Print extends Stmt {
  final Expr expression;

  Print(this.expression);

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitPrintStmt(this);
  }
}

