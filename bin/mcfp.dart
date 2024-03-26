import 'dart:io';

import 'package:mcfp/compiler.dart';
import 'package:mcfp/lexer.dart';
import 'package:mcfp/parser.dart';

import 'package:mcfp/_paths.dart' as paths;

void main(List<String> arguments) async {
  const scriptName = 'fib';
  final stopwatch = Stopwatch()..start();

  final input = File('scripts/$scriptName.mcfp').readAsStringSync();

  final inputElapsed = stopwatch.elapsedMicroseconds;
  print('Read input in ${inputElapsed / 1000} ms');
  print('');

  stopwatch.reset();
  final scanner = Scanner(input);
  final tokens = scanner.scanTokens();

  final scannerElapsed = stopwatch.elapsedMicroseconds;
  print('Scanned in ${scannerElapsed / 1000} ms');

  stopwatch.reset();
  final parser = Parser(tokens);
  final statements = parser.parse();

  final parserElapsed = stopwatch.elapsedMicroseconds;
  print('Parsed in ${parserElapsed / 1000} ms');

  stopwatch.reset();
  final compiler = Compiler(rootPath: 'scripts', rootEnvName: scriptName);
  compiler.compile(statements);

  final compilerElapsed = stopwatch.elapsedMicroseconds;
  print('Compiled in ${compilerElapsed / 1000} ms');
  print('');

  stopwatch.reset();
  compiler.writeToDir(paths.outPath);

  final writeElapsed = stopwatch.elapsedMicroseconds;
  print('Wrote to disk in ${writeElapsed / 1000} ms');
  stopwatch.reset();

  print('');
  print('Compilation total: ${(scannerElapsed + parserElapsed + compilerElapsed) / 1000} ms');
  print('IO total: ${(inputElapsed + writeElapsed) / 1000} ms');
}
