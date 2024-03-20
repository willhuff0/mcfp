tellraw @a [{"text":"MCFP: "},{"score":{"name":"fib_a","objective":"mcfp_runtime"}}]

# ASSIGN
scoreboard players operation fib_temp mcfp_runtime = fib_a mcfp_runtime

# ASSIGN
scoreboard players operation fib_a mcfp_runtime = fib_b mcfp_runtime

# ASSIGN
scoreboard players operation fib_fxrrcvl23wxp_a9j3v19m1ue7 mcfp_runtime = fib_temp mcfp_runtime
scoreboard players operation fib_fxrrcvl23wxp_a9j3v19m1ue7 mcfp_runtime += fib_b mcfp_runtime
scoreboard players operation fib_b mcfp_runtime = fib_fxrrcvl23wxp_a9j3v19m1ue7 mcfp_runtime
scoreboard players reset fib_fxrrcvl23wxp_a9j3v19m1ue7 mcfp_runtime

# WHILE CONDITION
scoreboard players set fib_fxrrcvl23wxp_3do0qb0b02xn mcfp_runtime 1000000000
scoreboard players set fib_fxrrcvl23wxp_dnjb0w4bzujt mcfp_runtime 0
execute if score fib_a mcfp_runtime < fib_fxrrcvl23wxp_3do0qb0b02xn mcfp_runtime run scoreboard players set fib_fxrrcvl23wxp_dnjb0w4bzujt mcfp_runtime 1
scoreboard players reset fib_fxrrcvl23wxp_3do0qb0b02xn mcfp_runtime

# WHILE REPEAT
execute if score should_break mcfp_runtime matches 1 run return 0
execute if score fib_fxrrcvl23wxp_dnjb0w4bzujt mcfp_runtime matches 1 run execute if function mcfp:fib_fxrrcvl23wxp run return 1
scoreboard players reset fib_fxrrcvl23wxp_dnjb0w4bzujt mcfp_runtime