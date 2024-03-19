import 'dart:math';

import 'package:mcfp_compiler/ast_expr.dart' as ast_expr;
import 'package:mcfp_compiler/ast_stmt.dart' as ast_stmt;
import 'package:mcfp_compiler/lexer.dart';

class Compiler implements ast_expr.Visitor<CompiledExpr> {
  final _globals = Environment(null);
  late Environment _environment;

  Compiler() {
    _environment = _globals;
  }

  // Expressions

  @override
  CompiledExpr visitBinaryExpr(ast_expr.Binary expr) {
    final left = _evaluate(expr.left);
    final right = _evaluate(expr.right);

    final constLeft = left.constValue;
    final constRight = right.constValue;
    if (constLeft != null && constRight != null) {
      switch (expr.operator.type) {
        case TokenType.GREATER:
          return CompiledExpr(constValue: _bool(constLeft > constRight));
        case TokenType.GREATER_EQUAL:
          return CompiledExpr(constValue: _bool(constLeft >= constRight));
        case TokenType.LESS:
          return CompiledExpr(constValue: _bool(constLeft < constRight));
        case TokenType.LESS_EQUAL:
          return CompiledExpr(constValue: _bool(constLeft <= constRight));
        case TokenType.MINUS:
          return CompiledExpr(constValue: constLeft - constRight);
        case TokenType.PLUS:
          return CompiledExpr(constValue: constLeft + constRight);
        case TokenType.SLASH:
          return CompiledExpr(constValue: constLeft ~/ constRight);
        case TokenType.STAR:
          return CompiledExpr(constValue: constLeft * constRight);
        case TokenType.BANG_EQUAL:
          return CompiledExpr(constValue: _bool(constLeft != constLeft));
        case TokenType.EQUAL:
          return CompiledExpr(constValue: _bool(constLeft == constRight));
        default:
          break;
      }
    }

    switch (expr.operator.type) {
      case TokenType.PLUS:
      case TokenType.MINUS:
      case TokenType.STAR:
      case TokenType.SLASH:
      case TokenType.EQUAL:
        final lines = <String>[];

        String leftName;
        String leftId;
        if (constLeft == null) {
          leftName = left.outName!;
          leftId = _environment.get(leftName);
        } else {
          final temp = _defineTemp(constLeft);
          lines.add(temp.line);
          leftName = temp.name;
          leftId = temp.id;
        }

        String rightId;
        if (constRight == null) {
          rightId = _environment.get(right.outName!);
        } else {
          final temp = _defineTemp(constRight);
          lines.add(temp.line);
          rightId = temp.id;
        }

        lines.add('scoreboard players operation $leftId mcfp_runtime ${expr.operator.type.mcLexeme} $rightId mcfp_runtime');

        // Cleanup temp right
        if (constRight != null) {
          lines.add('scoreboard players reset $rightId');
        }

        return CompiledExpr(lines: lines, outName: leftName);
    }

    return CompiledExpr(lines: [], outName: null, isConst: true, constValue: null);
  }

  CompiledExpr _evaluate(ast_expr.Expr expr) {
    return expr.accept(this);
  }

  TempVarDef _defineTemp(int value) {
    final name = _getNewId();
    final id = _getNewId();
    _environment.define(name, id);
    return TempVarDef(name, id, 'scoreboard players set $id mcfp_runtime $value');
  }

  int _bool(bool value) {
    return value ? 1 : 0;
  }

  static const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();
  String _getNewId() {
    return String.fromCharCodes(Iterable.generate(12, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  }
}

class Environment {
  final Environment? enclosing;

  Environment(this.enclosing);

  final _ids = <String, String>{};

  String get(String name) {
    if (_ids.containsKey(name)) {
      return _ids[name]!;
    }

    if (enclosing != null) return enclosing!.get(name);

    throw Exception('Variable $name not defined.');
  }

  void define(String name, String id) {
    _ids[name] = id;
  }

  void assign(String name, String id) {
    if (_ids.containsKey(name)) {
      _ids[name] = id;
      return;
    }

    if (enclosing != null) {
      enclosing!.assign(name, id);
      return;
    }

    throw Exception('Variable $name not defined.');
  }

  void deleteNamed(String name) {
    _ids.remove(name);
  }

  void deleteId(String id) {
    _ids.removeWhere((key, value) => value == id);
  }
}

class CompiledExpr {
  final List<String>? lines;
  final String? outName;
  final int? constValue;

  CompiledExpr({this.lines, this.outName, this.constValue});
}

class TempVarDef {
  final String name;
  final String id;
  final String line;

  TempVarDef(this.name, this.id, this.line);
}
