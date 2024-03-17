import 'dart:io';

class AstGenerator {
  Future<void> run() async {
    await _defineAst('lib/ast.dart', 'Expr', [
      'Binary   : Expr left, Token operator, Expr right',
      'Grouping : Expr expression',
      'Literal  : Object? value',
      'Unary    : Token operator, Expr right',
    ]);
  }

  Future<void> _defineAst(String outFile, String baseName, List<String> types) async {
    final file = File(outFile);
    await file.create(recursive: true);
    final writer = file.openWrite();

    writer.writeln("import 'package:mcfp_compiler/lexer.dart';");
    writer.writeln();
    writer.writeln("abstract class $baseName {");
    writer.writeln('  R accept<R>(Visitor<R> visitor);');
    writer.writeln('}');
    writer.writeln();

    _defineVisitor(writer, baseName, types);

    for (final type in types) {
      final className = type.split(':')[0].trim();
      final fields = type.split(':')[1].trim();
      _defineType(writer, baseName, className, fields);
    }

    await writer.flush();
    await writer.close();
  }

  void _defineType(IOSink writer, String baseName, String className, String fieldList) {
    writer.writeln('class $className extends $baseName {');

    // Fields
    final fields = fieldList.split(', ');
    for (final field in fields) {
      writer.writeln('  final $field;');
    }
    writer.writeln();

    // Constructor
    final constructorFields = fields.map((field) {
      return 'this.${field.split(' ')[1]}';
    }).join(', ');
    writer.writeln('  $className($constructorFields);');
    writer.writeln();

    // Visitor pattern
    writer.writeln('  @override');
    writer.writeln('  R accept<R>(Visitor<R> visitor) {');
    writer.writeln('    return visitor.visit$className$baseName(this);');
    writer.writeln('  }');

    writer.writeln('}');
    writer.writeln();
  }

  void _defineVisitor(IOSink writer, String baseName, List<String> types) {
    writer.writeln('abstract interface class Visitor<R> {');

    for (final type in types) {
      final typeName = type.split(':')[0].trim();
      writer.writeln('  R visit$typeName$baseName($typeName ${baseName.toLowerCase()});');
    }

    writer.writeln('}');
    writer.writeln();
  }
}
