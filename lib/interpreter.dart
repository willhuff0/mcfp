// import 'package:mcfp/ast_expr.dart' as ast_expr;
// import 'package:mcfp/ast_stmt.dart' as ast_stmt;
// import 'package:mcfp/lexer.dart';

// class Interpreter implements ast_expr.Visitor<Object?>, ast_stmt.Visitor<void> {
//   final _globals = Environment(null);
//   late Environment _environment;

//   Interpreter() {
//     _environment = _globals;

//     _globals.define('clock', ClockCallable());
//   }

//   void interpret(List<ast_stmt.Stmt> statements) {
//     // try catch runtime errors
//     for (final statement in statements) {
//       _execute(statement);
//     }
//   }

//   // Statements

//   @override
//   void visitExpressionStmt(ast_stmt.Expression stmt) {
//     _evaluate(stmt.expression);
//   }

//   @override
//   void visitASTFunctionStmt(ast_stmt.ASTFunction stmt) {
//     final function = MCFPFunction(stmt, _environment);
//     _environment.define(stmt.name.lexeme, function);
//   }

//   @override
//   void visitIfStmt(ast_stmt.If stmt) {
//     if (_isTruthy(_evaluate(stmt.condition))) {
//       _execute(stmt.thenBranch);
//     } else if (stmt.elseBranch != null) {
//       _execute(stmt.elseBranch!);
//     }
//   }

//   @override
//   void visitPrintStmt(ast_stmt.Print stmt) {
//     final value = _evaluate(stmt.expression);
//     print(value);
//   }

//   @override
//   void visitReturnStmt(ast_stmt.Return stmt) {
//     Object? value;
//     if (stmt.value != null) value = _evaluate(stmt.value!);

//     throw Return(value);
//   }

//   @override
//   void visitVarStmt(ast_stmt.Var stmt) {
//     Object? value;
//     if (stmt.initializer != null) {
//       value = _evaluate(stmt.initializer!);
//     }

//     _environment.define(stmt.name.lexeme, value);
//   }

//   @override
//   void visitWhileStmt(ast_stmt.While stmt) {
//     while (_isTruthy(_evaluate(stmt.condition))) {
//       _execute(stmt.body);
//     }
//   }

//   @override
//   void visitBlockStmt(ast_stmt.Block stmt) {
//     _executeBlock(stmt.statements, Environment(_environment));
//   }

//   void _executeBlock(List<ast_stmt.Stmt> statements, Environment environment) {
//     final previous = _environment;

//     try {
//       _environment = environment;

//       for (final statement in statements) {
//         _execute(statement);
//       }
//     } finally {
//       _environment = previous;
//     }
//   }

//   void _execute(ast_stmt.Stmt stmt) {
//     stmt.accept(this);
//   }

//   // Expressions

//   @override
//   Object? visitBinaryExpr(ast_expr.Binary expr) {
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
//       case TokenType.EQUAL_EQUAL:
//         return _isEqual(left, right);
//       default:
//         break;
//     }

//     return null;
//   }

//   @override
//   Object? visitCallExpr(ast_expr.Call expr) {
//     final callee = _evaluate(expr.callee);

//     final arguments = <Object?>[];
//     for (final argument in expr.arguments) {
//       arguments.add(_evaluate(argument));
//     }

//     if (callee is Callable) {
//       if (arguments.length != callee.arity()) {
//         throw Exception('Expected ${callee.arity()} arguments but got ${arguments.length}.');
//       }
//       return callee.call(this, arguments);
//     } else {
//       throw Exception('Can only call functions and classes.');
//     }
//   }

//   @override
//   Object? visitGroupingExpr(ast_expr.Grouping expr) {
//     return _evaluate(expr.expression);
//   }

//   @override
//   Object? visitLiteralExpr(ast_expr.Literal expr) {
//     return expr.value;
//   }

//   @override
//   Object? visitLogicalExpr(ast_expr.Logical expr) {
//     final left = _evaluate(expr.left);

//     if (expr.operator.type == TokenType.OR) {
//       if (_isTruthy(left)) return left;
//     } else {
//       if (!_isTruthy(left)) return left;
//     }

//     return _evaluate(expr.right);
//   }

//   @override
//   Object? visitUnaryExpr(ast_expr.Unary expr) {
//     final right = _evaluate(expr.right);

//     switch (expr.operator.type) {
//       case TokenType.BANG:
//         return !_isTruthy(right);
//       case TokenType.MINUS:
//         return -(right as double);
//       default:
//         break;
//     }

//     return null;
//   }

//   @override
//   Object? visitVariableExpr(ast_expr.Variable expr) {
//     return _environment.get(expr.name);
//   }

//   @override
//   Object? visitAssignExpr(ast_expr.Assign expr) {
//     final value = _evaluate(expr.value);
//     _environment.assign(expr.name, value);
//     return value;
//   }

//   Object? _evaluate(ast_expr.Expr expr) {
//     return expr.accept(this);
//   }

//   bool _isTruthy(Object? object) {
//     if (object == null) return false;
//     if (object is bool) return object;
//     return true;
//   }

//   bool _isEqual(Object? a, Object? b) {
//     if (a == null && b == null) return true;
//     if (a == null || b == null) return false;

//     return a == b;
//   }
// }

// class Environment {
//   final Environment? enclosing;

//   Environment(this.enclosing);

//   final _values = <String, Object?>{};

//   Object? get(Token name) {
//     if (_values.containsKey(name.lexeme)) {
//       return _values[name.lexeme];
//     }

//     if (enclosing != null) return enclosing!.get(name);

//     throw Exception('Variable ${name.lexeme} not defined.');
//   }

//   void define(String name, Object? value) {
//     _values[name] = value;
//   }

//   void assign(Token name, Object? value) {
//     if (_values.containsKey(name.lexeme)) {
//       _values[name.lexeme] = value;
//       return;
//     }

//     if (enclosing != null) {
//       enclosing!.assign(name, value);
//       return;
//     }

//     throw Exception('Variable ${name.lexeme} not defined.');
//   }
// }

// abstract interface class Callable {
//   int arity();
//   Object? call(Interpreter interpreter, List<Object?> arguments);
// }

// class ClockCallable implements Callable {
//   @override
//   int arity() {
//     return 0;
//   }

//   @override
//   Object? call(Interpreter interpreter, List<Object?> arguments) {
//     return DateTime.now().millisecondsSinceEpoch;
//   }

//   @override
//   String toString() {
//     return '<native fn>';
//   }
// }

// class MCFPFunction implements Callable {
//   final ast_stmt.ASTFunction _declaration;
//   final Environment _closure;

//   MCFPFunction(this._declaration, this._closure);

//   @override
//   int arity() {
//     return _declaration.params.length;
//   }

//   @override
//   Object? call(Interpreter interpreter, List<Object?> arguments) {
//     final environment = Environment(_closure);
//     for (var i = 0; i < _declaration.params.length; i++) {
//       environment.define(_declaration.params[i].lexeme, arguments[i]);
//     }

//     try {
//       interpreter._executeBlock(_declaration.body, environment);
//     } on Return catch (returnValue) {
//       return returnValue.value;
//     }
//     return null;
//   }

//   @override
//   String toString() {
//     return '<fn ${_declaration.name.lexeme}>';
//   }
// }

// class Return {
//   final Object? value;

//   Return(this.value);
// }
