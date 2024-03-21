# Minecraft Function Plus

A high level general purpose programming language that compiles into mcfunction



#### Features

- Arithmetic expressions
- Dynamically typed variables
  - int and bool only
- if / else statements
- while / for loops
- Functions
- Structs

#### Limitations

- No 'heap' or dynamic allocation
  - Variables are implemented via the scoreboard, which does not allow for dynamically generating new variables, so all variables must be defined at compile time
  - This means implementing a resizable list is not possible
- No recursive function calls
  - Because dynamic allocation is not possible, properties of recursive function calls cannot be stored. This could be rectified by allowing a fixed number of recursions, but I find that this defeats the purpose of supporting the feature, so I chose to leave it out.

## Example

Prints to chat the Fibonacci sequence up to 4181

```
var a = 0;
var temp;

for(var b = 1; a < 1000000000; b = temp + b) {
  print a;
  temp = a;
  a = b;
}
```

## Syntax

```
program        → declaration* EOF ;
```

```
declaration    → structDecl
               | funDecl
               | varDecl
               | statement ;

structDecl      → "struct" IDENTIFIER "{" varDecl* "}" ;
funDecl        → "func" function ;
varDecl        → "var" IDENTIFIER ( "=" expression )? ";" ;
```

```
statement      → exprStmt
               | forStmt
               | ifStmt
               | printStmt
               | returnStmt
               | whileStmt
               | block ;

exprStmt       → expression ";" ;
forStmt        → "for" "(" ( varDecl | exprStmt | ";" )
                           expression? ";"
                           expression? ")" statement ;
ifStmt         → "if" "(" expression ")" statement
                 ( "else" statement )? ;
printStmt      → "print" expression ";" ;
returnStmt     → "return" expression? ";" ;
whileStmt      → "while" "(" expression ")" statement ;
block          → "{" declaration* "}" ;
```

```
expression     → assignment ;

assignment     → ( call "." )? IDENTIFIER "=" assignment
               | logic_or ;

logic_or       → logic_and ( "or" logic_and )* ;
logic_and      → equality ( "and" equality )* ;
equality       → comparison ( ( "!=" | "==" ) comparison )* ;
comparison     → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
term           → factor ( ( "-" | "+" ) factor )* ;
factor         → unary ( ( "/" | "*" ) unary )* ;

unary          → ( "!" | "-" ) unary | call ;
call           → primary ( "(" arguments? ")" | "." IDENTIFIER )* ;
primary        → "true" | "false" | NUMBER | IDENTIFIER
               | "(" expression ")" ;
```

```
function       → IDENTIFIER "(" parameters? ")" block ;
parameters     → IDENTIFIER ( "," IDENTIFIER )* ;
arguments      → expression ( "," expression )* ;
```

```
NUMBER         → DIGIT+ ( "." DIGIT+ )? ;
IDENTIFIER     → ALPHA ( ALPHA | DIGIT )* ;
ALPHA          → "a" ... "z" | "A" ... "Z" | "_" ;
DIGIT          → "0" ... "9" ;
```