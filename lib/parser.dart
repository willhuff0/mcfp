import 'package:mcfp/ast_expr.dart';
import 'package:mcfp/ast_stmt.dart';
import 'package:mcfp/lexer.dart';

class ParseError implements Exception {
  final Token token;
  final String message;

  ParseError(this.token, this.message);

  @override
  String toString() {
    if (token.type == TokenType.EOF) {
      return 'Parse Error at line ${token.line}, EOF: $message';
    } else {
      return 'Parse Error at line ${token.line}, \'${token.lexeme}\': $message';
    }
  }
}

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
      if (_match(TokenType.FUNC)) return _function('function');
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
    if (_match(TokenType.RETURN)) return _returnStatement();
    if (_match(TokenType.BREAK)) return _breakStatement();
    if (_match(TokenType.WHILE)) return _whileStatement();
    if (_match(TokenType.STRUCT)) return _structStatement();
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

    Stmt body = Inliner(_statement());

    if (increment != null) {
      body = Block([
        body,
        Expression(increment),
      ]);
    }

    condition ??= Literal(true);
    body = While(condition, body);

    if (initializer != null) {
      body = InlineBlock([
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

  Stmt _returnStatement() {
    final keyword = _previous();
    Expr? value;
    if (!_check(TokenType.SEMICOLON)) {
      value = _expression();
    }

    _consume(TokenType.SEMICOLON, 'Expect \';\' after return value.');
    return Return(keyword, value);
  }

  Stmt _breakStatement() {
    final keyword = _previous();
    _consume(TokenType.SEMICOLON, 'Expect \';\' after \'break\'.');
    return Break(keyword);
  }

  Stmt _whileStatement() {
    _consume(TokenType.LEFT_PAREN, 'Expect \'(\' after \'while\'.');
    final condition = _expression();
    _consume(TokenType.RIGHT_PAREN, 'Expect \')\' after condition.');
    final body = _statement();

    return While(condition, body);
  }

  Stmt _structStatement() {
    final name = _consume(TokenType.IDENTIFIER, 'Expect name after \'struct\'.');

    _consume(TokenType.LEFT_BRACE, 'Expect \'{\' after struct name.');

    final properties = <Var>[];
    while (!_check(TokenType.RIGHT_BRACE)) {
      if (properties.length >= 255) {
        _error(_peek(), 'Can\'t have more than 255 properties in a struct.');
      }

      _consume(TokenType.VAR, 'Expected \'var\' inside struct body');
      properties.add(_varDeclaration() as Var);
    }
    _consume(TokenType.RIGHT_BRACE, 'Expect \'}\' after properties in struct.');

    return Struct(name, properties);
  }

  Stmt _expressionStatement() {
    final expr = _expression();
    _consume(TokenType.SEMICOLON, 'Expect \';\' after expression.');
    return Expression(expr);
  }

  ASTFunction _function(String kind) {
    final name = _consume(TokenType.IDENTIFIER, 'Expect $kind name.');
    _consume(TokenType.LEFT_PAREN, 'Expect \'(\' after $kind name.');
    final parameters = <Token>[];
    if (!_check(TokenType.RIGHT_PAREN)) {
      do {
        if (parameters.length >= 255) {
          _error(_peek(), 'Can\'t have more than 255 parameters.');
        }

        parameters.add(_consume(TokenType.IDENTIFIER, 'Expect parameter name'));
      } while (_match(TokenType.COMMA));
    }
    _consume(TokenType.RIGHT_PAREN, 'Expect \')\' after parameters.');

    _consume(TokenType.LEFT_BRACE, 'Expect \'{\' before $kind body.');
    final body = _block();
    return ASTFunction(name, parameters, body);
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
      } else if (expr is Get) {
        return Set(expr.object, expr.name, value);
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

    return _call();
  }

  Expr _call() {
    var expr = _primary();

    while (true) {
      if (_match(TokenType.LEFT_PAREN)) {
        expr = _finishCall(expr);
      } else if (_match(TokenType.DOT)) {
        final name = _consume(TokenType.IDENTIFIER, 'Expect property name after \'.\'.');
        expr = Get(expr, name);
      }
      {
        break;
      }
    }

    return expr;
  }

  Expr _finishCall(Expr callee) {
    final arguments = <Expr>[];
    if (!_check(TokenType.RIGHT_PAREN)) {
      do {
        if (arguments.length >= 255) {
          _error(_peek(), 'Can\'t have more than 255 arguments.');
        }
        arguments.add(_expression());
      } while (_match(TokenType.COMMA));
    }

    final paren = _consume(TokenType.RIGHT_PAREN, 'Expect \')\' after arguments.');

    return Call(callee, paren, arguments);
  }

  Expr _primary() {
    if (_match(TokenType.FALSE)) return Literal(false);
    if (_match(TokenType.TRUE)) return Literal(true);

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
    final error = ParseError(token, message);
    _reportParserError(error);
    return error;
  }

  void _synchronize() {
    _advance();

    while (!_isAtEnd()) {
      if (_previous().type == TokenType.SEMICOLON) return;

      switch (_peek().type) {
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

void _reportParserError(ParseError error) {
  print(error);
}
