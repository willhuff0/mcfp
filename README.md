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
- No floating point numbers, bytes
  - Minecraft supports storage of int8, int16, int32, int64, float32, and float64 values via the ```/data``` command. In order to perform arithmetic, these values must be copied to the scoreboard and are casted to int32
    - Vote here so Mojang adds floating point math: [Add a math parameter to /data modify - Minecraft Feedback](https://feedback.minecraft.net/hc/en-us/community/posts/360047978892-Add-a-math-parameter-to-data-modify)
  - Fixed point numbers are possible but I have not explicitly implemented them

## Example

#### fib.mcfp

```c
// Prints to chat the Fibonacci sequence up to n = 25, 46368

var a = 0;
var b = 1;

for (var n = 0; n < 25; n = n + 1) {
  var temp = a;
  a = b;
  b = temp + b;
  print temp;
}
```

Compiled in 10.89 ms with pretty and debug mode on.

<details>
  <summary>Compiled mcfunction</summary>
  
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
  scoreboard players set fib_b mcfp_runtime 1
  execute if function mcfp:fib_91lozjus6a5b run return 1

  # CLEAN
  scoreboard players reset fib_a mcfp_runtime
  scoreboard players reset fib_b mcfp_runtime
  scoreboard players reset fib_91lozjus6a5b_n mcfp_runtime
  scoreboard players reset fib_91lozjus6a5b_x3jf5nvq4k7h mcfp_runtime

  # RUNTIME CLEAN
  scoreboard players reset neg_one mcfp_runtime
  scoreboard players reset return_value mcfp_runtime
  scoreboard players reset should_break mcfp_runtime
  ```

  #### fib_91lozjus6a5b.mcfunction

  ```mcfunction
  # VAR
  scoreboard players set fib_91lozjus6a5b_n mcfp_runtime 0

  # WHILE CONDITION
  scoreboard players set fib_91lozjus6a5b_4y4atkm2319k mcfp_runtime 25
  scoreboard players set fib_91lozjus6a5b_x3jf5nvq4k7h mcfp_runtime 0
  execute if score fib_91lozjus6a5b_n mcfp_runtime < fib_91lozjus6a5b_4y4atkm2319k mcfp_runtime run scoreboard players set fib_91lozjus6a5b_x3jf5nvq4k7h mcfp_runtime 1
  scoreboard players reset fib_91lozjus6a5b_4y4atkm2319k mcfp_runtime

  # WHILE REPEAT
  scoreboard players set should_break mcfp_runtime 0
  execute if score fib_91lozjus6a5b_x3jf5nvq4k7h mcfp_runtime matches 1 run execute if function mcfp:fib_91lozjus6a5b_l1lcp73oc9te run return 1
  scoreboard players reset fib_91lozjus6a5b_x3jf5nvq4k7h mcfp_runtime
  ```

  #### fib_91lozjus6a5b_l1lcp73oc9te.mcfunction

  ```mcfunction
  # VAR
  scoreboard players operation fib_91lozjus6a5b_l1lcp73oc9te_temp mcfp_runtime = fib_a mcfp_runtime

  # ASSIGN
  scoreboard players operation fib_a mcfp_runtime = fib_b mcfp_runtime

  # ASSIGN
  scoreboard players operation fib_91lozjus6a5b_l1lcp73oc9te_za0ysaxto51i mcfp_runtime = fib_91lozjus6a5b_l1lcp73oc9te_temp mcfp_runtime
  scoreboard players operation fib_91lozjus6a5b_l1lcp73oc9te_za0ysaxto51i mcfp_runtime += fib_b mcfp_runtime
  scoreboard players operation fib_b mcfp_runtime = fib_91lozjus6a5b_l1lcp73oc9te_za0ysaxto51i mcfp_runtime
  scoreboard players reset fib_91lozjus6a5b_l1lcp73oc9te_za0ysaxto51i mcfp_runtime

  # PRINT
  tellraw @a [{"text":"fib: "},{"score":{"name":"fib_91lozjus6a5b_l1lcp73oc9te_temp","objective":"mcfp_runtime"}}]

  # ASSIGN
  scoreboard players set fib_91lozjus6a5b_l1lcp73oc9te_u41kmytd0iwn mcfp_runtime 1
  scoreboard players operation fib_91lozjus6a5b_l1lcp73oc9te_nr3e651z7b8q mcfp_runtime = fib_91lozjus6a5b_n mcfp_runtime
  scoreboard players operation fib_91lozjus6a5b_l1lcp73oc9te_nr3e651z7b8q mcfp_runtime += fib_91lozjus6a5b_l1lcp73oc9te_u41kmytd0iwn mcfp_runtime
  scoreboard players reset fib_91lozjus6a5b_l1lcp73oc9te_u41kmytd0iwn mcfp_runtime
  scoreboard players operation fib_91lozjus6a5b_n mcfp_runtime = fib_91lozjus6a5b_l1lcp73oc9te_nr3e651z7b8q mcfp_runtime
  scoreboard players reset fib_91lozjus6a5b_l1lcp73oc9te_nr3e651z7b8q mcfp_runtime

  # WHILE CONDITION
  scoreboard players set fib_91lozjus6a5b_l1lcp73oc9te_0xouqicezd1w mcfp_runtime 25
  scoreboard players set fib_91lozjus6a5b_l1lcp73oc9te_xr64ziewvzg2 mcfp_runtime 0
  execute if score fib_91lozjus6a5b_n mcfp_runtime < fib_91lozjus6a5b_l1lcp73oc9te_0xouqicezd1w mcfp_runtime run scoreboard players set fib_91lozjus6a5b_l1lcp73oc9te_xr64ziewvzg2 mcfp_runtime 1
  scoreboard players reset fib_91lozjus6a5b_l1lcp73oc9te_0xouqicezd1w mcfp_runtime

  # WHILE REPEAT
  execute if score should_break mcfp_runtime matches 1 run return 0
  execute if score fib_91lozjus6a5b_l1lcp73oc9te_xr64ziewvzg2 mcfp_runtime matches 1 run execute if function mcfp:fib_91lozjus6a5b_l1lcp73oc9te run return 1
  scoreboard players reset fib_91lozjus6a5b_l1lcp73oc9te_xr64ziewvzg2 mcfp_runtime
  ```
  
</details>

## Language

Grammar is similar to [Lox](https://craftinginterpreters.com/the-lox-language.html).

<details>
  <summary>Syntax</summary>

```
program        → declaration* EOF ;
```

```
declaration    → structDecl
               | funDecl
               | varDecl
               | statement ;

structDecl     → "struct" IDENTIFIER "{" varDecl* "}" ;
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
NUMBER         → DIGIT+ ;
STRING         → "\'" <any char except "\'">* "\'" ;
IDENTIFIER     → ALPHA ( ALPHA | DIGIT )* ;
ALPHA          → "a" ... "z" | "A" ... "Z" | "_" ;
DIGIT          → "0" ... "9" ;
```

</details>