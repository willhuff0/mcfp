import 'package:mcfp_compiler/ast_expr.dart';
import 'package:mcfp_compiler/ast_stmt.dart';
import 'package:mcfp_compiler/lexer.dart';

class ParseError implements Exception {}

class Parser {
  final List<Token> _tokens;
  var _current = 0;

  Parser(this._tokens);

  List<Stmt> parse() {
    final statements = <Stmt>[];
    while (!_isAtEnd()) {
      final statement = _declaration();
      if (statement != null) statements.add(statement);
    }

    return statements;
  }

  // Statements

  Stmt? _declaration() {
    try {
      if (_match(TokenType.VAR)) return _varDeclaration();

      return _statement();
    } on ParseError {
      _synchronize();
      return null;
    }
  }

  Stmt _varDeclaration() {
    final name = _consume(TokenType.IDENTIFIER, 'Expect variable name.');

    Expr? initializer;
    if (_match(TokenType.EQUAL)) {
      initializer = _expression();
    }

    _consume(TokenType.SEMICOLON, 'Expect \';\' after variable declaration.');
    return Var(name, initializer);
  }

  Stmt _statement() {
    if (_match(TokenType.FOR)) return _forStatement();
    if (_match(TokenType.IF)) return _ifStatement();
    if (_match(TokenType.PRINT)) return _printStatement();
    if (_match(TokenType.WHILE)) return _whileStatement();
    if (_match(TokenType.LEFT_BRACE)) return Block(_block());

    return _expressionStatement();
  }

  Stmt _forStatement() {
    _consume(TokenType.LEFT_PAREN, 'Expect \'(\' after \'for\'.');

    Stmt? initializer;
    if (_match(TokenType.SEMICOLON)) {
    } else if (_match(TokenType.VAR)) {
      initializer = _varDeclaration();
    } else {
      initializer = _expressionStatement();
    }

    Expr? condition;
    if (!_check(TokenType.SEMICOLON)) {
      condition = _expression();
    }
    _consume(TokenType.SEMICOLON, 'Expect \';\' after loop condition.');

    Expr? increment;
    if (!_check(TokenType.RIGHT_PAREN)) {
      increment = _expression();
    }
    _consume(TokenType.RIGHT_PAREN, 'Expect \')\' after for clauses.');

    var body = _statement();

    if (increment != null) {
      body = Block([
        body,
        Expression(increment),
      ]);
    }

    condition ??= Literal(true);
    body = While(condition, body);

    if (initializer != null) {
      body = Block([
        initializer,
        body,
      ]);
    }

    return body;
  }

  Stmt _ifStatement() {
    _consume(TokenType.LEFT_PAREN, 'Expect \'(\' after \'if\'.');
    final condition = _expression();
    _consume(TokenType.RIGHT_PAREN, 'Expect \')\' after condition.');

    final thenBranch = _statement();
    Stmt? elseBranch;
    if (_match(TokenType.ELSE)) {
      elseBranch = _statement();
    }

    return If(condition, thenBranch, elseBranch);
  }

  Stmt _printStatement() {
    final value = _expression();
    _consume(TokenType.SEMICOLON, 'Expect \';\' after value.');
    return Print(value);
  }

  Stmt _whileStatement() {
    _consume(TokenType.LEFT_PAREN, 'Expect \'(\' after \'while\'.');
    final condition = _expression();
    _consume(TokenType.LEFT_PAREN, 'Expect \')\' after condition.');
    final body = _statement();

    return While(condition, body);
  }

  Stmt _expressionStatement() {
    final expr = _expression();
    _consume(TokenType.SEMICOLON, 'Expect \';\' after expression.');
    return Expression(expr);
  }

  List<Stmt> _block() {
    final statements = <Stmt>[];

    while (!_check(TokenType.RIGHT_BRACE) && !_isAtEnd()) {
      final statement = _declaration();
      if (statement != null) statements.add(statement);
    }

    _consume(TokenType.RIGHT_BRACE, 'Expect \'}\' after block.');
    return statements;
  }

  // Expressions

  Expr _expression() {
    return _assignment();
  }

  Expr _assignment() {
    final expr = _or();

    if (_match(TokenType.EQUAL)) {
      final equals = _previous();
      final value = _assignment();

      if (expr is Variable) {
        final name = expr.name;
        return Assign(name, value);
      }

      _error(equals, 'Invalid assignment target.');
    }

    return expr;
  }

  Expr _or() {
    var expr = _and();

    while (_match(TokenType.OR)) {
      final operator = _previous();
      final right = _and();
      expr = Logical(expr, operator, right);
    }

    return expr;
  }

  Expr _and() {
    var expr = _equality();

    while (_match(TokenType.AND)) {
      final operator = _previous();
      final right = _equality();
      expr = Logical(expr, operator, right);
    }

    return expr;
  }

  Expr _equality() {
    var expr = _comparison();

    while (_matchAny([TokenType.BANG_EQUAL, TokenType.EQUAL_EQUAL])) {
      final operator = _previous();
      final right = _comparison();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  Expr _comparison() {
    var expr = _term();

    while (_matchAny([TokenType.GREATER, TokenType.GREATER_EQUAL, TokenType.LESS, TokenType.LESS_EQUAL])) {
      final operator = _previous();
      final right = _term();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  Expr _term() {
    var expr = _factor();

    while (_matchAny([TokenType.MINUS, TokenType.PLUS])) {
      final operator = _previous();
      final right = _factor();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  Expr _factor() {
    var expr = _unary();

    while (_matchAny([TokenType.SLASH, TokenType.STAR])) {
      final operator = _previous();
      final right = _unary();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  Expr _unary() {
    if (_matchAny([TokenType.BANG, TokenType.MINUS])) {
      final operator = _previous();
      final right = _unary();
      return Unary(operator, right);
    }

    return _primary();
  }

  Expr _primary() {
    if (_match(TokenType.FALSE)) return Literal(false);
    if (_match(TokenType.TRUE)) return Literal(true);
    if (_match(TokenType.NULL)) return Literal(null);

    if (_matchAny([TokenType.NUMBER, TokenType.STRING])) {
      return Literal(_previous().literal);
    }

    if (_match(TokenType.IDENTIFIER)) {
      return Variable(_previous());
    }

    if (_match(TokenType.LEFT_PAREN)) {
      final expr = _expression();
      _consume(TokenType.RIGHT_PAREN, 'Expect \')\' after expression.');
      return Grouping(expr);
    }

    throw _error(_peek(), 'Expected expression.');
  }

  Token _consume(TokenType type, String message) {
    if (_check(type)) return _advance();

    throw _error(_peek(), message);
  }

  ParseError _error(Token token, String message) {
    _reportParserError(token, message);
    return ParseError();
  }

  void _synchronize() {
    _advance();

    while (!_isAtEnd()) {
      if (_previous().type == TokenType.SEMICOLON) return;

      switch (_peek().type) {
        case TokenType.CLASS:
        case TokenType.FUNC:
        case TokenType.VAR:
        case TokenType.FOR:
        case TokenType.IF:
        case TokenType.WHILE:
        case TokenType.PRINT:
        case TokenType.RETURN:
          return;
        default:
          break;
      }

      _advance();
    }
  }

  bool _match(TokenType type) {
    if (_check(type)) {
      _advance();
      return true;
    }

    return false;
  }

  bool _matchAny(List<TokenType> types) {
    for (final type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }

    return false;
  }

  bool _check(TokenType type) {
    if (_isAtEnd()) return false;
    return _peek().type == type;
  }

  Token _advance() {
    if (!_isAtEnd()) _current++;
    return _previous();
  }

  bool _isAtEnd() {
    return _peek().type == TokenType.EOF;
  }

  Token _peek() {
    return _tokens[_current];
  }

  Token _previous() {
    return _tokens[_current - 1];
  }
}

void _reportParserError(Token token, String message) {
  if (token.type == TokenType.EOF) {
    print('Error at line ${token.line}, EOF: $message');
  } else {
    print('Error at line ${token.line}, \'${token.lexeme}\': $message');
  }
}
