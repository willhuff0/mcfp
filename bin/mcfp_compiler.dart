import 'dart:io';

import 'package:mcfp_compiler/interpreter.dart';
import 'package:mcfp_compiler/lexer.dart';
import 'package:mcfp_compiler/parser.dart';

void main(List<String> arguments) async {
  final input = File('input.mcfp').readAsStringSync();

  final scanner = Scanner(input);
  final tokens = scanner.scanTokens();

  final parser = Parser(tokens);
  final statements = parser.parse();

  final interpreter = Interpreter();
  interpreter.interpret(statements);

  //File('output.mcfunction').writeAsStringSync(compile(File('input.mcfp').readAsStringSync()));
}
