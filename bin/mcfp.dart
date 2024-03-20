import 'dart:io';

import 'package:mcfp/compiler.dart';
import 'package:mcfp/lexer.dart';
import 'package:mcfp/parser.dart';

void main(List<String> arguments) async {
  final input = File('input.mcfp').readAsStringSync();

  final scanner = Scanner(input);
  final tokens = scanner.scanTokens();

  final parser = Parser(tokens);
  final statements = parser.parse();

  final compiler = Compiler(rootEnvName: 'fib');
  compiler.compile(statements);
  compiler.writeToDir('out');
}
