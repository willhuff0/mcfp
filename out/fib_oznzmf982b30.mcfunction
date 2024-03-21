
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