// import 'package:mcfp_compiler/ast.dart';
// import 'package:mcfp_compiler/lexer.dart';

// class Compiler implements Visitor<List<String>> {
//   void compile(Expr expression) {
//     print(_evaluate(expression));
//   }

//   @override
//   List<String> visitBinaryExpr(Binary expr) {
//     final left = _evaluate(expr.left);
//     final right = _evaluate(expr.right);

//     switch (expr.operator.type) {
//       case TokenType.GREATER:
//         return (left as num) > (right as num);
//       case TokenType.GREATER_EQUAL:
//         return (left as num) >= (right as num);
//       case TokenType.LESS:
//         return (left as num) < (right as num);
//       case TokenType.LESS_EQUAL:
//         return (left as num) <= (right as num);
//       case TokenType.MINUS:
//         return (left as num) - (right as num);
//       case TokenType.PLUS:
//         if (left is num && right is num) {
//           return left + right;
//         }
//         if (left is String && right is String) {
//           return left + right;
//         }
//         break;
//       case TokenType.SLASH:
//         return (left as num) / (right as num);
//       case TokenType.STAR:
//         return (left as num) * (right as num);
//       case TokenType.BANG_EQUAL:
//         return !_isEqual(left, right);
//       case TokenType.EQUAL:
//         return _isEqual(left, right);
//       default:
//         break;
//     }

//     return [];
//   }

//   @override
//   List<String> visitGroupingExpr(Grouping expr) {
//     return _evaluate(expr.expression);
//   }

//   @override
//   List<String> visitLiteralExpr(Literal expr) {
//     return ['${expr.value} mcfp_runtime'];
//   }

//   @override
//   List<String> visitUnaryExpr(Unary expr) {
//     final right = _evaluate(expr.right);

//     switch (expr.operator.type) {
//       case TokenType.BANG:
//         return right.map((e) => 'unless $e').toList();
//       case TokenType.MINUS:
//         return right.map((e) => '-$e').toList();
//       default:
//         break;
//     }

//     return [];
//   }

//   List<String> _evaluate(Expr expr) {
//     return expr.accept(this);
//   }
// }
