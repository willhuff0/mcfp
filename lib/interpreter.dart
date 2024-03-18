import 'package:mcfp_compiler/ast_expr.dart' as ast_expr;
import 'package:mcfp_compiler/ast_stmt.dart' as ast_stmt;
import 'package:mcfp_compiler/lexer.dart';

class Interpreter implements ast_expr.Visitor<Object?>, ast_stmt.Visitor<void> {
  void interpret(List<ast_stmt.Stmt> statements) {
    // try catch runtime errors
    for (final statement in statements) {
      _execute(statement);
    }
  }

// Statements

  @override
  void visitExpressionStmt(ast_stmt.Expression stmt) {
    _evaluate(stmt.expression);
  }

  @override
  void visitPrintStmt(ast_stmt.Print stmt) {
    final value = _evaluate(stmt.expression);
    print(value);
  }

  void _execute(ast_stmt.Stmt stmt) {
    stmt.accept(this);
  }

  // Expressions

  @override
  Object? visitBinaryExpr(ast_expr.Binary expr) {
    final left = _evaluate(expr.left);
    final right = _evaluate(expr.right);

    switch (expr.operator.type) {
      case TokenType.GREATER:
        return (left as num) > (right as num);
      case TokenType.GREATER_EQUAL:
        return (left as num) >= (right as num);
      case TokenType.LESS:
        return (left as num) < (right as num);
      case TokenType.LESS_EQUAL:
        return (left as num) <= (right as num);
      case TokenType.MINUS:
        return (left as num) - (right as num);
      case TokenType.PLUS:
        if (left is num && right is num) {
          return left + right;
        }
        if (left is String && right is String) {
          return left + right;
        }
        break;
      case TokenType.SLASH:
        return (left as num) / (right as num);
      case TokenType.STAR:
        return (left as num) * (right as num);
      case TokenType.BANG_EQUAL:
        return !_isEqual(left, right);
      case TokenType.EQUAL:
        return _isEqual(left, right);
      default:
        break;
    }

    return null;
  }

  @override
  Object? visitGroupingExpr(ast_expr.Grouping expr) {
    return _evaluate(expr.expression);
  }

  @override
  Object? visitLiteralExpr(ast_expr.Literal expr) {
    return expr.value;
  }

  @override
  Object? visitUnaryExpr(ast_expr.Unary expr) {
    final right = _evaluate(expr.right);

    switch (expr.operator.type) {
      case TokenType.BANG:
        return !_isTruthy(right);
      case TokenType.MINUS:
        return -(right as double);
      default:
        break;
    }

    return null;
  }

  Object? _evaluate(ast_expr.Expr expr) {
    return expr.accept(this);
  }

  bool _isTruthy(Object? object) {
    if (object == null) return false;
    if (object is bool) return object;
    return true;
  }

  bool _isEqual(Object? a, Object? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;

    return a == b;
  }
}
