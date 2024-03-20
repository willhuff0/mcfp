import 'dart:io';

void main() async {
  await AstGenerator().run();
}

class AstGenerator {
  Future<void> run() async {
    await _defineAst('lib/ast_expr.dart', 'Expr', [
      'package:mcfp/lexer.dart',
    ], [
      'Assign   : Token name, Expr value',
      'Binary   : Expr left, Token operator, Expr right',
      'Call     : Expr callee, Token paren, List<Expr> arguments',
      'Grouping : Expr expression',
      'Literal  : Object? value',
      'Logical  : Expr left, Token operator, Expr right',
      'Unary    : Token operator, Expr right',
      'Variable : Token name',
    ]);

    await _defineAst('lib/ast_stmt.dart', 'Stmt', [
      'package:mcfp/lexer.dart',
      'package:mcfp/ast_expr.dart',
    ], [
      'Block       : List<Stmt> statements',
      'Expression  : Expr expression',
      'ASTFunction : Token name, List<Token> params, List<Stmt> body',
      'If          : Expr condition, Stmt thenBranch, Stmt? elseBranch',
      'Print       : Expr expression',
      'Return      : Token keyword, Expr? value',
      'Break       : Token keyword',
      'Var         : Token name, Expr? initializer',
      'While       : Expr condition, Stmt body',
      'WhilePass   : Expr? condition, String funcName',
    ]);
  }

  Future<void> _defineAst(String outFile, String baseName, List<String> imports, List<String> types) async {
    final file = File(outFile);
    await file.create(recursive: true);
    final writer = file.openWrite();

    for (final import in imports) {
      writer.writeln("import '$import';");
    }
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
