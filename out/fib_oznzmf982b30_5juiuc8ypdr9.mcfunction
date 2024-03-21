
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