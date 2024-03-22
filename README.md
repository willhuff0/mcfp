# Minecraft Function Plus

A high level general purpose programming language that compiles into mcfunction

#### Features

- Arithmetic expressions
  - int and bool only
- if / else statements
- while / for loops
- Functions
- Structs
- Import statements

#### Limitations

- No 'heap' or dynamic allocation
  - Variables are implemented via the scoreboard, which does not allow for dynamically generating new variables, so all variables must be defined at compile time
  - This means implementing a resizable list is not possible
- No recursive function calls
  - Because dynamic allocation is not possible, properties of recursive function calls cannot be stored. This could be rectified by allowing a fixed number of recursions, but I find that this defeats the purpose of supporting the feature, so I chose to leave it out.

## Example

Prints to chat the Fibonacci sequence up to n = 44, 701408733

```c
var a = 0;
var temp;

for(var b = 1; a < 1000000000; b = temp + b) {
  print a;
  temp = a;
  a = b;
}
```

<details>
  <summary>Compiled mcfunction</summary>

  Compiled with pretty and debug mode on.
  
  #### fib.mcfunction

  ```mcfunction
  # Compiled by mcfp_dart 1.0

  # RUNTIME SETUP

  scoreboard objectives add mcfp_runtime dummy
  scoreboard players reset * mcfp_runtime
  scoreboard objectives setdisplay sidebar mcfp_runtime
  scoreboard players set neg_one mcfp_runtime -1

  # END RUNTIME SETUP
  # WALKING SYNTAX TREE


  # VAR
  scoreboard players set fib_a mcfp_runtime 0

  # VAR
  scoreboard players set fib_temp mcfp_runtime 0
  execute if function mcfp:fib_oznzmf982b30 run return 1

  # CLEAN
  scoreboard players reset fib_a mcfp_runtime
  scoreboard players reset fib_temp mcfp_runtime
  ```

  #### fib_oznzmf982b30.mcfunction

  ```mcfunction
  # VAR
  scoreboard players set fib_oznzmf982b30_b mcfp_runtime 1

  # WHILE CONDITION
  scoreboard players set fib_oznzmf982b30_h9ruyup5510f mcfp_runtime 1000000000
  scoreboard players set fib_oznzmf982b30_vknqxk613cv4 mcfp_runtime 0
  execute if score fib_a mcfp_runtime < fib_oznzmf982b30_h9ruyup5510f mcfp_runtime run scoreboard players set fib_oznzmf982b30_vknqxk613cv4 mcfp_runtime 1
  scoreboard players reset fib_oznzmf982b30_h9ruyup5510f mcfp_runtime

  # WHILE REPEAT
  scoreboard players set should_break mcfp_runtime 0
  execute if score fib_oznzmf982b30_vknqxk613cv4 mcfp_runtime matches 1 run execute if function mcfp:fib_oznzmf982b30_5juiuc8ypdr9 run return 1
  scoreboard players reset fib_oznzmf982b30_vknqxk613cv4 mcfp_runtime

  # CLEAN
  scoreboard players reset fib_oznzmf982b30_b mcfp_runtime
  ```

  #### fib_oznzmf982b30_5juiuc8ypdr9.mcfunction

  ```mcfunction
  # PRINT
  tellraw @a [{"text":"MCFP: "},{"score":{"name":"fib_a","objective":"mcfp_runtime"}}]

  # ASSIGN
  scoreboard players operation fib_temp mcfp_runtime = fib_a mcfp_runtime

  # ASSIGN
  scoreboard players operation fib_a mcfp_runtime = fib_oznzmf982b30_b mcfp_runtime

  # ASSIGN
  scoreboard players operation fib_oznzmf982b30_5juiuc8ypdr9_7d7bm9f3a4ys mcfp_runtime = fib_temp mcfp_runtime
  scoreboard players operation fib_oznzmf982b30_5juiuc8ypdr9_7d7bm9f3a4ys mcfp_runtime += fib_oznzmf982b30_b mcfp_runtime
  scoreboard players operation fib_oznzmf982b30_b mcfp_runtime = fib_oznzmf982b30_5juiuc8ypdr9_7d7bm9f3a4ys mcfp_runtime
  scoreboard players reset fib_oznzmf982b30_5juiuc8ypdr9_7d7bm9f3a4ys mcfp_runtime

  # WHILE CONDITION
  scoreboard players set fib_oznzmf982b30_5juiuc8ypdr9_0eh3qtaf8kfn mcfp_runtime 1000000000
  scoreboard players set fib_oznzmf982b30_5juiuc8ypdr9_fjo9kv182fzj mcfp_runtime 0
  execute if score fib_a mcfp_runtime < fib_oznzmf982b30_5juiuc8ypdr9_0eh3qtaf8kfn mcfp_runtime run scoreboard players set fib_oznzmf982b30_5juiuc8ypdr9_fjo9kv182fzj mcfp_runtime 1
  scoreboard players reset fib_oznzmf982b30_5juiuc8ypdr9_0eh3qtaf8kfn mcfp_runtime

  # WHILE REPEAT
  execute if score should_break mcfp_runtime matches 1 run return 0
  execute if score fib_oznzmf982b30_5juiuc8ypdr9_fjo9kv182fzj mcfp_runtime matches 1 run execute if function mcfp:fib_oznzmf982b30_5juiuc8ypdr9 run return 1
  scoreboard players reset fib_oznzmf982b30_5juiuc8ypdr9_fjo9kv182fzj mcfp_runtime
  ```
  
</details>

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
               | importStmt
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
importStmt     → "import" STRING ";" ;
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
STRING         → "\"" <any char except "\"">* "\"" ;
IDENTIFIER     → ALPHA ( ALPHA | DIGIT )* ;
ALPHA          → "a" ... "z" | "A" ... "Z" | "_" ;
DIGIT          → "0" ... "9" ;
```