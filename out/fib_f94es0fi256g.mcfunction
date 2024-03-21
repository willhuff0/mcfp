
# PRINT
tellraw @a [{"text":"MCFP: "},{"score":{"name":"fib_a","objective":"mcfp_runtime"}}]

# ASSIGN
scoreboard players operation fib_temp mcfp_runtime = fib_a mcfp_runtime

# ASSIGN
scoreboard players operation fib_a mcfp_runtime = fib_b mcfp_runtime

# ASSIGN
scoreboard players operation fib_f94es0fi256g_eaklo85dcyzp mcfp_runtime = fib_temp mcfp_runtime
scoreboard players operation fib_f94es0fi256g_eaklo85dcyzp mcfp_runtime += fib_b mcfp_runtime
scoreboard players operation fib_b mcfp_runtime = fib_f94es0fi256g_eaklo85dcyzp mcfp_runtime
scoreboard players reset fib_f94es0fi256g_eaklo85dcyzp mcfp_runtime

# WHILE CONDITION
scoreboard players set fib_f94es0fi256g_j51op68hjtar mcfp_runtime 1000000000
scoreboard players set fib_f94es0fi256g_f8fb4nf994qg mcfp_runtime 0
execute if score fib_a mcfp_runtime < fib_f94es0fi256g_j51op68hjtar mcfp_runtime run scoreboard players set fib_f94es0fi256g_f8fb4nf994qg mcfp_runtime 1
scoreboard players reset fib_f94es0fi256g_j51op68hjtar mcfp_runtime

# WHILE REPEAT
execute if score should_break mcfp_runtime matches 1 run return 0
execute if score fib_f94es0fi256g_f8fb4nf994qg mcfp_runtime matches 1 run execute if function mcfp:fib_f94es0fi256g run return 1
scoreboard players reset fib_f94es0fi256g_f8fb4nf994qg mcfp_runtime