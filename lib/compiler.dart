import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:mcfp/ast_expr.dart' as ast_expr;
import 'package:mcfp/ast_stmt.dart' as ast_stmt;
import 'package:mcfp/lexer.dart';
import 'package:mcfp/parser.dart';
import 'package:path/path.dart' as p;

const _pretty = true;
const _debug = true;

const _mcNamespace = 'mcfp';

class CompileError implements Exception {
  final Token token;
  final String message;

  CompileError(this.token, this.message);

  @override
  String toString() {
    if (token.type == TokenType.EOF) {
      return 'Compile Error at line ${token.line}, EOF: $message';
    } else {
      return 'Compile Error at line ${token.line}, \'${token.lexeme}\': $message';
    }
  }
}

class Compiler implements ast_expr.Visitor<CompiledExpr>, ast_stmt.Visitor<void> {
  final String rootPath;

  final Environment _globalEnv;
  late Environment env;

  Compiler({required this.rootPath, required String rootEnvName}) : _globalEnv = Environment(null, rootEnvName) {
    env = _globalEnv;

    const versionTag = 'Compiled by mcfp_dart 1.0';

    env.lines.add('# $versionTag');

    if (_pretty) {
      env.commentAll([
        'RUNTIME SETUP',
      ]);
    }

    env.lines.add('scoreboard objectives add mcfp_runtime dummy');
    env.lines.add('scoreboard players reset * mcfp_runtime');
    if (_debug) env.lines.add('scoreboard objectives setdisplay sidebar mcfp_runtime');

    env.lines.add('scoreboard players set neg_one mcfp_runtime -1');

    if (_pretty) {
      env.commentAll([
        'END RUNTIME SETUP',
        'WALKING SYNTAX TREE',
      ]);
    }

    _defineNativeFunc('getGameTime', 0, (compiler, arguments) {
      final resultName = compiler._defineNewVar();
      compiler.env.lines.add('execute store result score ${compiler.env.eval(resultName)} mcfp_runtime run time query gametime');
      return CompiledExpr(name: resultName, isTemp: true);
    });
  }

  void compile(List<ast_stmt.Stmt> statements) {
    for (final statement in statements) {
      _build(statement);
    }
  }

  void writeToDir(String path) {
    final dir = Directory(path);
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    dir.createSync(recursive: true);
    _globalEnv.cleanAllVars();
    _globalEnv.writeToDir(path);
  }

  // Statements

  @override
  void visitExpressionStmt(ast_stmt.Expression stmt) {
    _evaluate(stmt.expression);
    if (stmt.expression is ast_expr.Call) {
      env.lines.removeLast();
    }
  }

  @override
  void visitASTFunctionStmt(ast_stmt.ASTFunction stmt) {
    final funcEnv = Environment(env, stmt.name.lexeme);

    final func = CompiledFunc(env.evalShallow(stmt.name.lexeme), stmt, funcEnv);
    env.defineFunc(stmt.name.lexeme, func);

    for (final param in stmt.params) {
      funcEnv.define(param.lexeme);
    }

    _buildBlock(stmt.body, funcEnv);
  }

  @override
  void visitIfStmt(ast_stmt.If stmt) {
    if (_pretty) env.comment('IF CONDITION');

    final condition = _evaluate(stmt.condition);

    if (_pretty) env.comment('IF BODY');

    if (condition.value == null) {
      _ifBranch(condition.name!, true, stmt.thenBranch);

      final elseBranch = stmt.elseBranch;
      if (elseBranch != null) {
        _ifBranch(condition.name!, false, elseBranch);
      }

      if (condition.isTemp) env.undefineAndReset(condition.name!);
    } else {
      if (condition.value == 1) {
        _ifBranch(null, true, stmt.thenBranch);
      } else {
        final elseBranch = stmt.elseBranch;
        if (elseBranch != null) {
          _ifBranch(null, false, elseBranch);
        }
      }
    }
  }

  void _ifBranch(String? conditionName, bool trueCondition, ast_stmt.Stmt branch) {
    final conditionPart = conditionName != null ? 'execute ${trueCondition ? 'if' : 'unless'} score ${env.evalShallow(conditionName)} mcfp_runtime matches 1 run ' : '';

    final branchName = _getNewName();
    final branchEnv = Environment(env, branchName);

    final branchStatements = branch is ast_stmt.Block ? branch.statements : [branch];

    _buildBlock(branchStatements, branchEnv);

    if (branchEnv.lines.length == 1) {
      env.lines.add('$conditionPart${branchEnv.lines.first}');
      branchEnv.destroy();
    } else {
      env.lines.add('${conditionPart}execute if function $_mcNamespace:${env.evalShallow(branchName)} run return 1');
    }
  }

  @override
  void visitPrintStmt(ast_stmt.Print stmt) {
    if (_pretty) env.comment('PRINT');

    final value = _evaluate(stmt.expression);
    if (value is CompiledStringExpr) {
      env.lines.add('tellraw @a "MCFP: ${value.stringValue}"');
    } else {
      if (value.value == null) {
        final json = jsonEncode([
          {
            'text': 'MCFP: ',
          },
          {
            'score': {
              'name': env.eval(value.name!),
              'objective': 'mcfp_runtime',
            },
          },
        ]);
        env.lines.add('tellraw @a $json');

        if (value.isTemp) env.undefineAndReset(value.name!);
      } else {
        env.lines.add('tellraw @a "MCFP: ${value.value}"');
      }
    }
  }

  @override
  void visitReturnStmt(ast_stmt.Return stmt) {
    if (stmt.value != null) {
      final value = _evaluate(stmt.value!);
      if (value.value == null) {
        env.lines.add('scoreboard players operation return_value mcfp_runtime = ${env.eval(value.name!)} mcfp_runtime');
      } else {
        env.lines.add('scoreboard players set return_value mcfp_runtime ${value.value}');
      }
    }

    env.lines.add('return 1');
  }

  @override
  void visitBreakStmt(ast_stmt.Break stmt) {
    env.lines.add('scoreboard players set should_break mcfp_runtime 1');
    env.lines.add('return 0');
  }

  @override
  void visitVarStmt(ast_stmt.Var stmt) {
    if (_pretty) env.comment('VAR');

    if (stmt.initializer != null) {
      final initializer = _evaluate(stmt.initializer!);

      if (initializer is CompiledStructExpr) {
        for (var i = 0; i < initializer.properties.length; i++) {
          final property = initializer.properties[i];

          CompiledExpr argument;
          if (initializer.arguments.length <= i) {
            if (property.initializer == null) {
              argument = CompiledExpr(value: 0);
            } else {
              argument = _evaluate(property.initializer!);
            }
          } else {
            argument = initializer.arguments[i];
          }

          final variableName = '${stmt.name.lexeme}_${property.name.lexeme}';

          env.define(variableName);

          if (argument.value == null) {
            env.lines.add('scoreboard players operation ${env.evalShallow(variableName)} mcfp_runtime = ${env.eval(argument.name!)} mcfp_runtime');

            if (argument.isTemp) env.undefineAndReset(argument.name!);
          } else {
            env.lines.add('scoreboard players set ${env.evalShallow(variableName)} mcfp_runtime ${argument.value!}');
          }
        }
      } else {
        env.define(stmt.name.lexeme);

        if (initializer.value == null) {
          env.lines.add('scoreboard players operation ${env.eval(stmt.name.lexeme)} mcfp_runtime = ${env.eval(initializer.name!)} mcfp_runtime');
        } else {
          env.lines.add('scoreboard players set ${env.eval(stmt.name.lexeme)} mcfp_runtime ${initializer.value}');
        }
      }
    } else {
      env.define(stmt.name.lexeme);
      env.lines.add('scoreboard players set ${env.eval(stmt.name.lexeme)} mcfp_runtime 0');
    }
  }

  @override
  void visitWhileStmt(ast_stmt.While stmt) {
    if (_pretty) env.comment('WHILE CONDITION');

    final condition = _evaluate(stmt.condition);

    if (condition.value == null) {
      final body = stmt.body;
      final bodyName = _getNewName();
      final bodyStatements = body is ast_stmt.Block ? body.statements : [body];
      bodyStatements.add(ast_stmt.WhilePass(stmt.condition, env.evalShallow(bodyName)));
      _buildBlock(bodyStatements, Environment(env, bodyName));

      if (_pretty) env.comment('WHILE REPEAT');

      env.lines.add('scoreboard players set should_break mcfp_runtime 0');
      final conditionPart = 'execute if score ${env.evalShallow(condition.name!)} mcfp_runtime matches 1 run ';
      env.lines.add('${conditionPart}execute if function $_mcNamespace:${env.evalShallow(bodyName)} run return 1');

      if (condition.isTemp) env.undefineAndReset(condition.name!);
    } else {
      if (condition.value == 1) {
        final body = stmt.body;
        final bodyName = _getNewName();
        final bodyStatements = body is ast_stmt.Block ? body.statements : [body];
        bodyStatements.add(ast_stmt.WhilePass(null, env.evalShallow(bodyName)));
        _buildBlock(bodyStatements, Environment(env, bodyName));

        if (_pretty) env.comment('WHILE REPEAT');

        env.lines.add('scoreboard players set should_break mcfp_runtime 0');
        env.lines.add('execute if function $_mcNamespace:${env.evalShallow(bodyName)} run return 1');
      }
    }
  }

  @override
  void visitWhilePassStmt(ast_stmt.WhilePass stmt) {
    if (stmt.condition != null) {
      if (_pretty) env.comment('WHILE CONDITION');

      final condition = _evaluate(stmt.condition!);

      if (_pretty) env.comment('WHILE REPEAT');

      env.lines.add('execute if score should_break mcfp_runtime matches 1 run return 0');
      final conditionPart = 'execute if score ${env.evalShallow(condition.name!)} mcfp_runtime matches 1 run ';
      env.lines.add('${conditionPart}execute if function $_mcNamespace:${stmt.funcName} run return 1');

      if (condition.isTemp) env.undefineAndReset(condition.name!);
    } else {
      env.lines.add('execute if score should_break mcfp_runtime matches 1 run return 0');
      env.lines.add('execute if function $_mcNamespace:${stmt.funcName} run return 1');
    }
  }

  @override
  void visitStructStmt(ast_stmt.Struct stmt) {
    env.defineFunc(stmt.name.lexeme, StructInitializerCallable(stmt.properties));
  }

  @override
  void visitImportStmt(ast_stmt.Import stmt) {
    final path = p.join(rootPath, stmt.path.literal as String);

    final input = File(path).readAsStringSync();

    final scanner = Scanner(input);
    final tokens = scanner.scanTokens();

    final parser = Parser(tokens);
    final statements = parser.parse();

    if (_pretty) {
      env.comment('IMPORT: ${stmt.path.literal as String}');
    }

    compile(statements);

    if (_pretty) {
      env.comment('END IMPORT');
    }

    final newEnvName = _getNewName();
    env.lines.add('function mcfp:${env.evalShallow(newEnvName)}');
    env = Environment(env, newEnvName);
  }

  @override
  void visitBlockStmt(ast_stmt.Block stmt) {
    final name = _getNewName();
    _buildBlock(stmt.statements, Environment(env, name));
    env.lines.add('execute if function $_mcNamespace:${env.evalShallow(name)} run return 1');
  }

  @override
  void visitInlineBlockStmt(ast_stmt.InlineBlock stmt) {
    for (final statements in stmt.statements) {
      _build(statements);
    }
  }

  @override
  void visitInlinerStmt(ast_stmt.Inliner stmt) {
    final inlined = stmt.statement;
    if (inlined is ast_stmt.Block) {
      for (final statement in inlined.statements) {
        _build(statement);
      }
    } else {
      _build(inlined);
    }
  }

  void _buildBlock(List<ast_stmt.Stmt> statements, Environment env) {
    final previous = this.env;

    try {
      this.env = env;

      for (final statement in statements) {
        _build(statement);
      }
    } finally {
      this.env = previous;
    }
  }

  void _build(ast_stmt.Stmt stmt) {
    stmt.accept(this);
  }

  // Expressions

  @override
  CompiledExpr visitBinaryExpr(ast_expr.Binary expr) {
    final left = _evaluate(expr.left);
    final right = _evaluate(expr.right);

    final constLeft = left.value;
    final constRight = right.value;
    if (constLeft != null && constRight != null) {
      switch (expr.operator.type) {
        case TokenType.GREATER:
          return CompiledExpr(value: _bool(constLeft > constRight));
        case TokenType.GREATER_EQUAL:
          return CompiledExpr(value: _bool(constLeft >= constRight));
        case TokenType.LESS:
          return CompiledExpr(value: _bool(constLeft < constRight));
        case TokenType.LESS_EQUAL:
          return CompiledExpr(value: _bool(constLeft <= constRight));
        case TokenType.MINUS:
          return CompiledExpr(value: constLeft - constRight);
        case TokenType.PLUS:
          return CompiledExpr(value: constLeft + constRight);
        case TokenType.SLASH:
          return CompiledExpr(value: constLeft ~/ constRight);
        case TokenType.STAR:
          return CompiledExpr(value: constLeft * constRight);
        case TokenType.BANG_EQUAL:
          return CompiledExpr(value: _bool(constLeft != constLeft));
        case TokenType.EQUAL_EQUAL:
          return CompiledExpr(value: _bool(constLeft == constRight));
        default:
          break;
      }
    }

    switch (expr.operator.type) {
      case TokenType.PLUS:
      case TokenType.MINUS:
      case TokenType.STAR:
      case TokenType.SLASH:
        String rightName;
        if (constRight == null) {
          rightName = right.name!;
        } else {
          rightName = _defineNewVar();
          env.lines.add('scoreboard players set ${env.eval(rightName)} mcfp_runtime $constRight');
        }

        final mcOperator = switch (expr.operator.type) {
          TokenType.PLUS => '+=',
          TokenType.MINUS => '-=',
          TokenType.STAR => '*=',
          TokenType.SLASH => '/=',
          TokenType.EQUAL => '-',
          _ => '',
        };

        final resultName = _defineNewVar();
        if (constLeft == null) {
          env.lines.add('scoreboard players operation ${env.eval(resultName)} mcfp_runtime = ${env.eval(left.name!)} mcfp_runtime');
        } else {
          env.lines.add('scoreboard players set ${env.eval(resultName)} mcfp_runtime $constLeft');
        }

        env.lines.add('scoreboard players operation ${env.eval(resultName)} mcfp_runtime $mcOperator ${env.eval(rightName)} mcfp_runtime');

        if (left.isTemp) {
          env.undefineAndReset(left.name!);
        }
        if (constRight != null) {
          env.undefineAndReset(rightName);
        } else if (right.isTemp) {
          env.undefineAndReset(right.name!);
        }

        return CompiledExpr(name: resultName, isTemp: true);
      case TokenType.GREATER:
      case TokenType.GREATER_EQUAL:
      case TokenType.LESS:
      case TokenType.LESS_EQUAL:
      case TokenType.BANG_EQUAL:
      case TokenType.EQUAL_EQUAL:
        String leftName;
        if (constLeft == null) {
          leftName = left.name!;
        } else {
          leftName = _defineNewVar();
          env.lines.add('scoreboard players set ${env.eval(leftName)} mcfp_runtime $constLeft');
        }

        String rightName;
        if (constRight == null) {
          rightName = right.name!;
        } else {
          rightName = _defineNewVar();
          env.lines.add('scoreboard players set ${env.eval(rightName)} mcfp_runtime $constRight');
        }

        final mcOperator = switch (expr.operator.type) {
          TokenType.GREATER => '>',
          TokenType.GREATER_EQUAL => '>=',
          TokenType.LESS => '<',
          TokenType.LESS_EQUAL => '<=',
          TokenType.BANG_EQUAL => '==',
          TokenType.EQUAL_EQUAL => '==',
          _ => '',
        };

        final negated = expr.operator.type == TokenType.BANG_EQUAL;

        final resultName = _defineNewVar();
        env.lines.add('scoreboard players set ${env.eval(resultName)} mcfp_runtime 0');

        env.lines.add('execute ${negated ? 'unless' : 'if'} score ${env.eval(leftName)} mcfp_runtime $mcOperator ${env.eval(rightName)} mcfp_runtime run scoreboard players set ${env.eval(resultName)} mcfp_runtime 1');

        if (constLeft != null) {
          env.undefineAndReset(leftName);
        } else if (left.isTemp) {
          env.undefineAndReset(left.name!);
        }
        if (constRight != null) {
          env.undefineAndReset(rightName);
        } else if (right.isTemp) {
          env.undefineAndReset(right.name!);
        }

        return CompiledExpr(name: resultName, isTemp: true);
      default:
        break;
    }

    return CompiledExpr();
  }

  @override
  CompiledExpr visitCallExpr(ast_expr.Call expr) {
    final callee = _evaluate(expr.callee);

    final func = env.evalFunc(callee.name!);

    if (func != null) {
      if (!func.checkArity(expr.arguments.length)) {
        throw _error(expr.paren, 'Expected ${func.arityString()} arguments but got ${expr.arguments.length}.');
      }

      final arguments = <CompiledExpr>[];
      for (final argument in expr.arguments) {
        arguments.add(_evaluate(argument));
      }

      return func.call(this, arguments);
    } else {
      throw _error(expr.paren, '${callee.name!} does not exist or is not a function.');
    }
  }

  @override
  CompiledExpr visitGetExpr(ast_expr.Get expr) {
    final object = _evaluate(expr.object);
    if (object.value == null) {
      return CompiledExpr(name: '${object.name}_${expr.name.lexeme}');
    } else {
      throw _error(expr.name, 'Getter is not valid on const value (${object.value})');
    }
  }

  @override
  CompiledExpr visitGroupingExpr(ast_expr.Grouping expr) {
    return _evaluate(expr.expression);
  }

  @override
  CompiledExpr visitLiteralExpr(ast_expr.Literal expr) {
    if (expr.value is int) {
      return CompiledExpr(value: expr.value as int);
    } else {
      return CompiledExpr(value: expr.value == true ? 1 : 0);
    }
  }

  @override
  CompiledExpr visitLogicalExpr(ast_expr.Logical expr) {
    final resultName = _defineNewVar();
    env.lines.add('scoreboard players set ${env.eval(resultName)} 0');

    if (expr.operator.type == TokenType.OR) {
      // OR

      final left = _evaluate(expr.left);

      if (left.value == null) {
        env.lines.add('execute if score ${env.eval(left.name!)} mcfp_runtime matches 1 run scoreboard players set ${env.eval(resultName)} 1');

        if (left.isTemp) env.undefineAndReset(left.name!);
      } else {
        return CompiledExpr(value: left.value == 1 ? 1 : 0);
      }

      final right = _evaluate(expr.right);

      if (right.value == null) {
        env.lines.add('execute if score ${env.eval(right.name!)} mcfp_runtime matches 1 run scoreboard players set ${env.eval(resultName)} 1');

        if (right.isTemp) env.undefineAndReset(right.name!);
      } else {
        return CompiledExpr(value: right.value == 1 ? 1 : 0);
      }
    } else {
      // AND

      var line = '';

      final left = _evaluate(expr.left);

      if (left.value == null) {
        line = 'execute if score ${env.eval(left.name!)} mcfp_runtime matches 1';
      } else if (left.value == 0) {
        return CompiledExpr(value: 0);
      }

      final right = _evaluate(expr.right);

      if (right.value == null) {
        line += ' run execute if score ${env.eval(right.name!)} mcfp_runtime matches 1';
      } else if (right.value == 0) {
        return CompiledExpr(value: 0);
      }

      line += ' run scoreboard players set ${env.eval(resultName)} 1';

      env.lines.add(line);

      if (left.isTemp) env.undefineAndReset(left.name!);
      if (right.isTemp) env.undefineAndReset(right.name!);
    }

    return CompiledExpr(name: resultName, isTemp: true);
  }

  @override
  CompiledExpr visitSetExpr(ast_expr.Set expr) {
    final value = _evaluate(expr.value);
    final object = _evaluate(expr.object);

    if (object.value == null) {
      final name = '${object.name}_${value.name}';

      if (value.value == null) {
        env.lines.add('scoreboard players operation ${env.eval(name)} mcfp_runtime = ${env.eval(value.name!)} mcfp_runtime');

        if (value.isTemp) env.undefineAndReset(value.name!);
      } else {
        env.lines.add('scoreboard players set ${env.eval(name)} mcfp_runtime ${value.value!}');
      }

      return value;
    } else {
      throw _error(expr.name, 'Setter is not valid on const value (${object.value})');
    }
  }

  @override
  CompiledExpr visitUnaryExpr(ast_expr.Unary expr) {
    final right = _evaluate(expr.right);

    switch (expr.operator.type) {
      case TokenType.BANG:
        if (right.value == null) {
          final temp = _defineNewVar();
          env.lines.add('scoreboard players operation ${env.eval(temp)} mcfp_runtime = ${env.eval(right.name!)} mcfp_runtime');
          env.lines.add('execute if score ${env.eval(temp)} mcfp_runtime matches 1 run scoreboard players set ${env.eval(right.name!)} mcfp_runtime 0');
          env.lines.add('execute unless score ${env.eval(temp)} mcfp_runtime matches 1 run scoreboard players set ${env.eval(right.name!)} mcfp_runtime 1');
          env.undefineAndReset(temp);
          return CompiledExpr(name: right.name!);
        } else {
          return CompiledExpr(value: right.value == 1 ? 0 : 1);
        }
      case TokenType.MINUS:
        if (right.value == null) {
          env.lines.add('scoreboard players operation ${env.eval(right.name!)} mcfp_runtime *= neg_one mcfp_runtime');
          return CompiledExpr(name: right.name!);
        } else {
          return CompiledExpr(value: -right.value!);
        }
      default:
        break;
    }

    return CompiledExpr();
  }

  @override
  CompiledExpr visitVariableExpr(ast_expr.Variable expr) {
    return CompiledExpr(name: expr.name.lexeme);
  }

  @override
  CompiledExpr visitAssignExpr(ast_expr.Assign expr) {
    if (_pretty) env.comment('ASSIGN');

    final value = _evaluate(expr.value);

    if (value.value == null) {
      env.lines.add('scoreboard players operation ${env.eval(expr.name.lexeme)} mcfp_runtime = ${env.eval(value.name!)} mcfp_runtime');

      if (value.isTemp) env.undefineAndReset(value.name!);
    } else {
      env.lines.add('scoreboard players set ${env.eval(expr.name.lexeme)} mcfp_runtime ${value.value!}');
    }

    return value;
  }

  CompiledExpr _evaluate(ast_expr.Expr expr) {
    return expr.accept(this);
  }

  int _bool(bool value) {
    return value ? 1 : 0;
  }

  static const _chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final _rnd = Random();
  String _getNewName() {
    return String.fromCharCodes(Iterable.generate(12, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  }

  String _defineNewVar() {
    final name = _getNewName();
    env.define(name);
    return name;
  }

  void _defineNativeFunc(String name, int numArgs, CompiledExpr Function(Compiler compiler, List<CompiledExpr> arguments) func) {
    env.defineFunc(name, NativeCallable(numArgs, func));
  }

  CompileError _error(Token token, String message) {
    final error = CompileError(token, message);
    _reportCompileError(error);
    return error;
  }
}

void _reportCompileError(CompileError error) {
  print(error);
}

class Environment {
  final Environment? enclosing;
  final String name;

  final _enclosed = <Environment>[];

  Environment(this.enclosing, this.name) {
    enclosing?._enclosed.add(this);
  }

  final lines = <String>[];

  final _vars = <String>[];
  final _funcs = <String, Callable>{};

  String get namespace => enclosing == null ? '${name}_' : '${enclosing!.namespace}${name}_';

  void define(String name) {
    if (_vars.contains(name)) {
      throw Exception('A variable with the name $name already exists in the scope $namespace');
    }

    _vars.add(name);
  }

  void undefine(String name) {
    _vars.remove(name);
  }

  void undefineAndReset(String name) {
    lines.add('scoreboard players reset ${evalShallow(name)} mcfp_runtime');
    undefine(name);
  }

  String evalShallow(String name) => '$namespace$name';

  String eval(String name) {
    if (_vars.contains(name)) return '$namespace$name';
    if (enclosing != null) return enclosing!.eval(name);
    throw Exception('A variable with the name $name does not exists in the scope $namespace');
  }

  void defineFunc(String name, Callable func) => _funcs[name] = func;

  Callable? evalFunc(String name) => _funcs[name] ?? enclosing?.evalFunc(name);

  void comment(String text) {
    lines.addAll(['', '# $text']);
  }

  void commentAll(List<String> texts) {
    lines.addAll(['', ...texts.map((e) => '# $e'), '']);
  }

  void destroy() {
    enclosing?._enclosed.remove(this);
    for (final enclosed in _enclosed) {
      enclosed.destroy();
    }
  }

  void cleanAllVars() {
    if (_pretty && _vars.isNotEmpty) {
      comment('CLEAN');
    }
    for (final variable in _vars) {
      lines.add('scoreboard players reset $namespace$variable mcfp_runtime');
    }
    for (final enclosed in _enclosed) {
      enclosed.cleanAllVars();
    }
  }

  void writeToDir(String dir) {
    File(p.join(dir, '${enclosing == null ? name : '${enclosing!.namespace}$name'}.mcfunction')).writeAsStringSync(lines.join('\n'));
    for (final enclosed in _enclosed) {
      enclosed.writeToDir(dir);
    }
  }
}

class CompiledExpr {
  final String? name;
  final int? value;
  final bool isTemp;

  CompiledExpr({this.name, this.value, this.isTemp = false});
}

class CompiledStringExpr extends CompiledExpr {
  final String stringValue;

  CompiledStringExpr({super.name, super.value, super.isTemp, required this.stringValue});
}

class CompiledStructExpr extends CompiledExpr {
  final List<ast_stmt.Var> properties;
  final List<CompiledExpr> arguments;

  CompiledStructExpr({super.name, super.value, super.isTemp, required this.properties, required this.arguments});
}

abstract interface class Callable {
  String arityString();
  bool checkArity(int arity);
  CompiledExpr call(Compiler compiler, List<CompiledExpr> arguments);
}

class CompiledFunc extends Callable {
  final String _path;
  final ast_stmt.ASTFunction _declaration;
  final Environment _closure;

  CompiledFunc(this._path, this._declaration, this._closure);

  @override
  String arityString() {
    return _declaration.params.length.toString();
  }

  @override
  bool checkArity(int arity) {
    return arity == _declaration.params.length;
  }

  @override
  CompiledExpr call(Compiler compiler, List<CompiledExpr> arguments) {
    for (var i = 0; i < arguments.length; i++) {
      final argument = arguments[i];
      final param = _declaration.params[i];

      if (argument.value == null) {
        compiler.env.lines.add('scoreboard players operation ${_closure.eval(param.lexeme)} mcfp_runtime = ${compiler.env.eval(argument.name!)} mcfp_runtime');

        if (argument.isTemp) compiler.env.undefineAndReset(argument.name!);
      } else {
        compiler.env.lines.add('scoreboard players set ${_closure.eval(param.lexeme)} mcfp_runtime ${argument.value!}');
      }
    }

    compiler.env.lines.add('function $_mcNamespace:$_path');

    final resultName = compiler._defineNewVar();
    compiler.env.lines.add('scoreboard players operation ${compiler.env.eval(resultName)} mcfp_runtime = return_value mcfp_runtime');

    return CompiledExpr(name: resultName, isTemp: true);
  }
}

class NativeCallable extends Callable {
  final int numArgs;
  final CompiledExpr Function(Compiler compiler, List<CompiledExpr> arguments) func;

  NativeCallable(this.numArgs, this.func);

  @override
  String arityString() {
    return numArgs.toString();
  }

  @override
  bool checkArity(int arity) {
    return arity == numArgs;
  }

  @override
  CompiledExpr call(Compiler compiler, List<CompiledExpr> arguments) => func(compiler, arguments);
}

class StructInitializerCallable extends Callable {
  final List<ast_stmt.Var> properties;

  StructInitializerCallable(this.properties);

  @override
  String arityString() {
    return '${properties.length} or fewer';
  }

  @override
  bool checkArity(int arity) {
    return arity <= properties.length;
  }

  @override
  CompiledExpr call(Compiler compiler, List<CompiledExpr> arguments) {
    return CompiledStructExpr(properties: properties, arguments: arguments);
  }
}
