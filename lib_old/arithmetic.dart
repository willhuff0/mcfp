import 'compiler.dart';

// Result is stored in resultVar
List<String> exprToMcf(Scope scope, String expr, {String resultVar = 'arithmetic_result'}) {
  final infix = _exprToTokens(expr);
  final postfix = _infixToPostfix(infix);
  final mcf = _postfixToMcf(scope, postfix, resultVar);
  return mcf;
}

List<String> _exprToTokens(String expr) {
  final chars = expr.split('')..removeWhere((element) => element == ' ');
  final tokens = <String>[];

  var currentToken = '';
  for (final char in chars) {
    switch (char) {
      case '+' || '-' || '*' || '/' || '(' || ')':
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

  return tokens;
}

final _precedence = {
  '*': 3,
  '/': 3,
  '+': 2,
  '-': 2,
  '(': 1,
};

List<String> _infixToPostfix(List<String> infixTokens) {
  final operatorStack = _Stack<String>();
  final postfixTokens = <String>[];

  for (final token in infixTokens) {
    switch (token) {
      case '(':
        operatorStack.push(token);
        break;
      case ')':
        var topToken = operatorStack.pop();
        while (topToken != '(') {
          postfixTokens.add(topToken);
          topToken = operatorStack.pop();
        }
        break;
      case '+' || '-' || '*' || '/':
        while (operatorStack.isNotEmpty && _precedence[operatorStack.peek]! >= _precedence[token]!) {
          postfixTokens.add(operatorStack.pop());
        }
        operatorStack.push(token);
        break;
      default:
        postfixTokens.add(token);
        break;
    }
  }

  while (operatorStack.isNotEmpty) {
    postfixTokens.add(operatorStack.pop());
  }

  return postfixTokens;
}

List<String> _postfixToMcf(Scope scope, List<String> postfixTokens, String resultVar) {
  final mcf = <String>[];

  final operandStack = _Stack<_Operand>();

  var tempVarIndex = 0;

  for (final token in postfixTokens) {
    switch (token) {
      case '+' || '-' || '*' || '/':
        final operand2 = operandStack.pop();
        final operand1 = operandStack.pop();

        if (operand1.isConst && operand2.isConst) {
          final constResult = switch (token) {
            '+' => operand1.constValue! + operand2.constValue!,
            '-' => operand1.constValue! - operand2.constValue!,
            '*' => operand1.constValue! * operand2.constValue!,
            '/' => operand1.constValue! ~/ operand2.constValue!,
            _ => throw Exception('Invalid operator when evaluating const expression: ${operand1.name} $token ${operand2.name}'),
          };

          operandStack.push(_Operand(constResult.toString(), constValue: constResult));
        } else {
          final result = operandStack.isEmpty
              ? resultVar
              : operand1.isTemp
                  ? operand1.name
                  : 'temp_${tempVarIndex++}';

          final resultScoreboard = operandStack.isEmpty ? 'mcfp_runtime' : 'mcfp_runtime_arithmetic';

          mcf.addAll([
            if ((operandStack.isEmpty && operand1.name != resultVar) || !operand1.isTemp) operand1.isConst ? 'scoreboard players set $result $resultScoreboard ${operand1.name}' : 'scoreboard players operation $result $resultScoreboard = ${operand1.name} mcfp_runtime',
            if (operand2.isConst) ...[
              'scoreboard players set temp_const mcfp_runtime_arithmetic ${operand2.name}',
              'scoreboard players operation $result $resultScoreboard $token= temp_const mcfp_runtime_arithmetic',
            ] else
              'scoreboard players operation $result $resultScoreboard $token= ${operand2.name} ${operand2.isTemp ? 'mcfp_runtime_arithmetic' : 'mcfp_runtime'}',
          ]);

          operandStack.push(_Operand(result, isTemp: true));
        }
        break;
      default:
        if (token == '(' || token == ')') {
          operandStack.push(_Operand(token));
        } else {
          final constValue = int.tryParse(token);
          if (constValue != null) {
            operandStack.push(_Operand(token, constValue: constValue));
          } else {
            operandStack.push(_Operand(scope.lookupVar(token)!.mcId));
          }
        }
        break;
    }
  }

  if (mcf.isEmpty) {
    final operand = operandStack.pop();
    if (operand.isConst) {
      mcf.add('scoreboard players set $resultVar ${operand.name}');
    } else {
      mcf.add('scoreboard players operation $resultVar mcfp_runtime = ${operand.name} ${operand.isTemp ? 'mcfp_runtime_arithmetic' : 'mcfp_runtime'}');
    }
  }

  return mcf;
}

class _Operand {
  String name;
  int? constValue;
  bool isTemp;

  _Operand(this.name, {this.constValue, this.isTemp = false});

  bool get isConst => constValue != null;
}

class _Stack<E> {
  final _list = <E>[];

  void push(E value) => _list.add(value);

  E pop() => _list.removeLast();

  E get peek => _list.last;

  bool get isEmpty => _list.isEmpty;
  bool get isNotEmpty => _list.isNotEmpty;

  @override
  String toString() => _list.toString();
}
