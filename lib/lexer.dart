// ignore_for_file: constant_identifier_names

import 'package:characters/characters.dart';

enum TokenType {
  // Single-character tokens
  LEFT_PAREN('('),
  RIGHT_PAREN(')'),
  LEFT_BRACE('{'),
  RIGHT_BRACE('}'),
  COMMA(','),
  DOT('.'),
  MINUS('-'),
  PLUS('+'),
  SEMICOLON(';'),
  SLASH('/'),
  STAR('*'),
  AND('&'),
  OR('|'),

  // One or two character tokens
  BANG('!'),
  BANG_EQUAL('!='),
  EQUAL('='),
  EQUAL_EQUAL('=='),
  GREATER('>'),
  GREATER_EQUAL('>='),
  LESS('<'),
  LESS_EQUAL('<='),

  // Literals
  IDENTIFIER('[a-zA-Z_][a-zA-Z_0-9]*'),
  STRING(''),
  NUMBER(''),

  // Keywords
  ELSE(''),
  FALSE(''),
  TRUE(''),
  FUNC(''),
  FOR(''),
  IF(''),
  PRINT(''),
  RETURN(''),
  BREAK(''),
  VAR(''),
  WHILE(''),
  STRUCT(''),

  EOF('');

  final String mcLexeme;

  const TokenType(this.mcLexeme);
}

class Token {
  final TokenType type;
  final String lexeme;
  final Object? literal;
  final int line;

  Token(this.type, this.lexeme, this.literal, this.line);

  @override
  String toString() => '$type $lexeme $literal';
}

const _keywords = {
  'else': TokenType.ELSE,
  'false': TokenType.FALSE,
  'true': TokenType.TRUE,
  'func': TokenType.FUNC,
  'for': TokenType.FOR,
  'if': TokenType.IF,
  'print': TokenType.PRINT,
  'return': TokenType.RETURN,
  'break': TokenType.BREAK,
  'var': TokenType.VAR,
  'while': TokenType.WHILE,
  'struct': TokenType.STRUCT,
};

class Scanner {
  final String _source;
  final List<Token> _tokens = <Token>[];
  var _start = 0;
  var _current = 0;
  var _line = 1;

  Scanner(this._source);

  List<Token> scanTokens() {
    while (!_isAtEnd()) {
      _start = _current;
      _scanToken();
    }

    _tokens.add(Token(TokenType.EOF, '', null, _line));
    return _tokens;
  }

  bool _isAtEnd() {
    return _current >= _source.length;
  }

  void _scanToken() {
    final c = _advance();
    switch (c) {
      case '(':
        _addToken(TokenType.LEFT_PAREN);
        break;
      case ')':
        _addToken(TokenType.RIGHT_PAREN);
        break;
      case '{':
        _addToken(TokenType.LEFT_BRACE);
        break;
      case '}':
        _addToken(TokenType.RIGHT_BRACE);
        break;
      case ',':
        _addToken(TokenType.COMMA);
        break;
      case '.':
        _addToken(TokenType.DOT);
        break;
      case '-':
        _addToken(TokenType.MINUS);
        break;
      case '+':
        _addToken(TokenType.PLUS);
        break;
      case ';':
        _addToken(TokenType.SEMICOLON);
        break;
      case '*':
        _addToken(TokenType.STAR);
        break;
      case '&':
        _addToken(TokenType.AND);
        break;
      case '|':
        _addToken(TokenType.OR);
        break;
      case '!':
        _addToken(_match('=') ? TokenType.BANG_EQUAL : TokenType.BANG);
        break;
      case '=':
        _addToken(_match('=') ? TokenType.EQUAL_EQUAL : TokenType.EQUAL);
        break;
      case '<':
        _addToken(_match('=') ? TokenType.LESS_EQUAL : TokenType.LESS);
        break;
      case '>':
        _addToken(_match('=') ? TokenType.GREATER_EQUAL : TokenType.GREATER);
        break;
      case '/':
        if (_match('/')) {
          // A comment goes until the end of the line.
          while (_peek() != '\n' && !_isAtEnd()) {
            _advance();
          }
        } else {
          _addToken(TokenType.SLASH);
        }
        break;
      case ' ':
      case '\r':
      case '\t':
        // Ignore whitespace.
        break;
      case '\n':
        _line++;
        break;
      case '\'':
        _string();
        break;
      default:
        if (_isDigit(c)) {
          _number();
        } else if (_isAlpha(c)) {
          _identifier();
        } else {
          throw Exception('Error ($_line): Unexpected character. \'$c\'');
        }
    }
  }

  String _advance() => _source[_current++];

  void _addToken(TokenType type) {
    _addTokenWithLiteral(type, null);
  }

  void _addTokenWithLiteral(TokenType type, Object? literal) {
    final text = _source.substring(_start, _current);
    _tokens.add(Token(type, text, literal, _line));
  }

  bool _match(String expected) {
    if (_isAtEnd()) return false;
    if (_source[_current] != expected) return false;

    _current++;
    return true;
  }

  String _peek() {
    if (_isAtEnd()) return r'\0';
    return _source[_current];
  }

  String _peekNext() {
    if (_current + 1 >= _source.length) return r'\0';
    return _source[_current + 1];
  }

  void _string() {
    while (_peek() != '\'' && !_isAtEnd()) {
      if (_peek() != '\n') _line++;
      _advance();
    }

    if (_isAtEnd()) {
      throw Exception('Error ($_line): Unterminated string.');
    }

    _advance();

    final value = _source.substring(_start + 1, _current - 1);
    _addTokenWithLiteral(TokenType.STRING, value);
  }

  void _number() {
    while (_isDigit(_peek())) {
      _advance();
    }

    // if (_peek() == '.' && _isDigit(_peekNext())) {
    //   _advance();

    //   while (_isDigit(_peek())) {
    //     _advance();
    //   }
    // }

    final value = int.parse(_source.substring(_start, _current));
    _addTokenWithLiteral(TokenType.NUMBER, value);
  }

  bool _isDigit(String c) {
    if (c.isEmpty) return false;
    return '0123456789'.characters.any((element) => element == c);
  }

  void _identifier() {
    while (_isAlphaNumeric(_peek())) {
      _advance();
    }

    final text = _source.substring(_start, _current);
    final type = _keywords[text] ?? TokenType.IDENTIFIER;
    _addToken(type);
  }

  bool _isAlpha(String c) {
    if (c.isEmpty) return false;
    final lowerCaseC = c.toLowerCase();
    return 'abcdefghijklmnopqrstuvwxyz'.characters.any((element) => element == lowerCaseC);
  }

  bool _isAlphaNumeric(String c) {
    return _isAlpha(c) || _isDigit(c);
  }
}
