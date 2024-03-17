import 'dart:convert';
import 'dart:io';

import 'package:mcfp_compiler/ast.dart';
import 'package:mcfp_compiler/ast_generator.dart';
import 'package:mcfp_compiler/ast_printer.dart';
import 'package:mcfp_compiler/interpreter.dart';
import 'package:mcfp_compiler/lexer.dart';
import 'package:mcfp_compiler/parser.dart';

void main(List<String> arguments) async {
  // final expression = Binary(
  //   Unary(
  //     Token(TokenType.MINUS, '-', null, 1),
  //     Literal(123),
  //   ),
  //   Token(TokenType.STAR, '*', null, 1),
  //   Grouping(
  //     Literal(45),
  //   ),
  // );

  // print(AstPrinter().print(expression));

  final input = File('input.mcfp').readAsStringSync();

  final scanner = Scanner(input);
  final tokens = scanner.scanTokens();

  final parser = Parser(tokens);
  final expression = parser.parse();

  if (expression == null) return;

  print(AstPrinter().print(expression));

  final interpreter = Interpreter();
  interpreter.interpret(expression);

  // print(JsonEncoder.withIndent(' ').convert(tokens
  //     .map((e) => {
  //           'type': e.type.name,
  //           'lexeme': e.lexeme,
  //           'literal': e.literal,
  //           'line': e.line,
  //         })
  //     .toList()));

  //File('output.mcfunction').writeAsStringSync(compile(File('input.mcfp').readAsStringSync()));
}
