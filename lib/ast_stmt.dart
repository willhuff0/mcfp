import 'package:mcfp/lexer.dart';
import 'package:mcfp/ast_expr.dart';

abstract class Stmt {
  R accept<R>(Visitor<R> visitor);
}

abstract interface class Visitor<R> {
  R visitBlockStmt(Block stmt);
  R visitInlineBlockStmt(InlineBlock stmt);
  R visitInlinerStmt(Inliner stmt);
  R visitExpressionStmt(Expression stmt);
  R visitASTFunctionStmt(ASTFunction stmt);
  R visitIfStmt(If stmt);
  R visitPrintStmt(Print stmt);
  R visitReturnStmt(Return stmt);
  R visitBreakStmt(Break stmt);
  R visitVarStmt(Var stmt);
  R visitWhileStmt(While stmt);
  R visitWhilePassStmt(WhilePass stmt);
  R visitStructStmt(Struct stmt);
  R visitImportStmt(Import stmt);
}

class Block extends Stmt {
  final List<Stmt> statements;

  Block(this.statements);

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitBlockStmt(this);
  }
}

class InlineBlock extends Stmt {
  final List<Stmt> statements;

  InlineBlock(this.statements);

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitInlineBlockStmt(this);
  }
}

class Inliner extends Stmt {
  final Stmt statement;

  Inliner(this.statement);

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitInlinerStmt(this);
  }
}

class Expression extends Stmt {
  final Expr expression;

  Expression(this.expression);

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitExpressionStmt(this);
  }
}

class ASTFunction extends Stmt {
  final Token name;
  final List<Token> params;
  final List<Stmt> body;

  ASTFunction(this.name, this.params, this.body);

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitASTFunctionStmt(this);
  }
}

class If extends Stmt {
  final Expr condition;
  final Stmt thenBranch;
  final Stmt? elseBranch;

  If(this.condition, this.thenBranch, this.elseBranch);

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitIfStmt(this);
  }
}

class Print extends Stmt {
  final Expr expression;

  Print(this.expression);

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitPrintStmt(this);
  }
}

class Return extends Stmt {
  final Token keyword;
  final Expr? value;

  Return(this.keyword, this.value);

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitReturnStmt(this);
  }
}

class Break extends Stmt {
  final Token keyword;

  Break(this.keyword);

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitBreakStmt(this);
  }
}

class Var extends Stmt {
  final Token name;
  final Expr? initializer;

  Var(this.name, this.initializer);

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitVarStmt(this);
  }
}

class While extends Stmt {
  final Expr condition;
  final Stmt body;

  While(this.condition, this.body);

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitWhileStmt(this);
  }
}

class WhilePass extends Stmt {
  final Expr? condition;
  final String funcName;

  WhilePass(this.condition, this.funcName);

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitWhilePassStmt(this);
  }
}

class Struct extends Stmt {
  final Token name;
  final List<Var> properties;

  Struct(this.name, this.properties);

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitStructStmt(this);
  }
}

class Import extends Stmt {
  final Token path;

  Import(this.path);

  @override
  R accept<R>(Visitor<R> visitor) {
    return visitor.visitImportStmt(this);
  }
}

