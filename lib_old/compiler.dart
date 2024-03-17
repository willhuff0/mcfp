import 'dart:math';

import 'arithmetic.dart';

const obfuscateIds = false;

const _chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
Random _rnd = Random();
String _getNewId() => String.fromCharCodes(Iterable.generate(6, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

String compile(String source) {
  final globalScope = Scope(null);

  final lines = source.split('\n')..removeWhere((element) => element.trim().startsWith('//'));

  Func? func;
  var startLine = 0;

  var depth = 0;
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();

    final tokens = _lineToTokens(line);

    for (var k = 0; k < tokens.length; k++) {
      final token = tokens[k];
      switch (token) {
        case 'func':
          depth = 0;

          final name = tokens[k + 1];
          final id = obfuscateIds ? _getNewId() : '${name}_${_getNewId()}';
          func = Func(id, name, []);

          startLine = i + 1;
          break;
        case '{':
          depth++;
          break;
        case '}':
          depth--;
          if (depth == 0) {
            func!.lines.addAll(lines.sublist(startLine, i));
            globalScope.registerFunc(func.name, func);
            func = null;
          }
          break;
      }
    }
  }

  return globalScope.lookupFunc('load')!.getCompiled(globalScope).join('\n');
}

List<String> _lineToTokens(String line) {
  final words = line.trim().split(' ').where((element) => element.trim() == element).map((e) => e.replaceAll(';', '')).toList();
  final tokens = <String>[];

  for (final word in words) {
    final chars = word.split('')..removeWhere((element) => element == ' ');

    var currentToken = '';
    for (final char in chars) {
      switch (char) {
        case '{' || '}' || '(' || ')':
          if (currentToken.isNotEmpty) {
            tokens.add(currentToken);
            currentToken = '';
          }
          tokens.add(char);
          break;
        default:
          currentToken += char;
          break;
      }
    }

    if (currentToken.isNotEmpty) {
      tokens.add(currentToken);
    }
  }

  return tokens;
}

List<String> compileFunc(Scope parent, List<String> lines) {
  final scope = Scope(parent);
  final result = <String>[];

  var i = 0;
  for (final line in lines) {
    final words = line.trim().split(' ').where((element) => element.trim() == element).map((e) => e.replaceAll(';', '')).toList();

    switch (words.first) {
      case var x when x == 'int' || x == 'bool' || x == 'string':
        final type = VariableType.values.byName(x);
        final name = words[1];

        if (scope.lookupVar(name) != null) {
          throw Exception('Error at $i: a variable with the name $name already exists');
        }

        final id = obfuscateIds ? _getNewId() : '${name}_${_getNewId()}';
        final variable = Variable(id, name, type);
        scope.registerVar(name, variable);

        if (words.length >= 4 && words[2] == '=') {
          // Has setter

          final setter = words.sublist(3).join();

          switch (type) {
            case VariableType.int:
              result.addAll(exprToMcf(scope, setter, resultVar: variable.mcId));
              break;
            case VariableType.bool:
              result.add('scoreboard players set ${variable.mcId} mcfp_runtime ${setter == 'true' ? '1' : '0'}');
              break;
            case VariableType.string:
              throw Exception('string not implemented');
          }
        } else {
          // Initialize default value

          switch (type) {
            case VariableType.int:
            case VariableType.bool:
              result.add('scoreboard players set ${variable.mcId} mcfp_runtime 0');
              break;
            case VariableType.string:
              throw Exception('string not implemented');
          }
        }
        break;
      case 'call':
        final name = words[1];
        final func = scope.lookupFunc(name);
        result.addAll(func!.getCompiled(scope));
        break;
    }

    i++;
  }

  return result;
}

class Variable {
  final String mcId;
  final String name;
  final VariableType type;

  Variable(this.mcId, this.name, this.type);
}

enum VariableType {
  int,
  bool,
  string,
}

class Func {
  final String mcId;
  final String name;
  final List<String> lines;

  Func(this.mcId, this.name, this.lines);

  List<String>? _compiled;
  List<String> getCompiled(Scope scope) => _compiled ??= compileFunc(scope, lines);
}

class Scope {
  final Scope? parent;

  Scope(this.parent);

  final _variables = <String, Variable>{};

  final _functions = <String, Func>{};

  Variable? lookupVar(String name) => _variables[name] ?? parent?.lookupVar(name);

  void registerVar(String name, Variable variable) => _variables[name] = variable;

  Func? lookupFunc(String name) => _functions[name] ?? parent?.lookupFunc(name);

  void registerFunc(String name, Func func) => _functions[name] = func;
}
