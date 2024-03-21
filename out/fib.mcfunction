# Compiled by mcfp_dart 1.0

# RUNTIME SETUP

scoreboard objectives add mcfp_runtime dummy
scoreboard players reset * mcfp_runtime
scoreboard objectives setdisplay sidebar mcfp_runtime
scoreboard players set neg_one mcfp_runtime -1

# END RUNTIME SETUP
# WALKING SYNTAX TREE


# VAR
scoreboard players set fib_bruh_x mcfp_runtime 10
scoreboard players set fib_bruh_y mcfp_runtime 10
scoreboard players set fib_bruh_z mcfp_runtime 10

# PRINT
scoreboard players operation fib_pgs3gb749vq9 mcfp_runtime = fib_bruh_y mcfp_runtime
scoreboard players operation fib_pgs3gb749vq9 mcfp_runtime += fib_bruh_x mcfp_runtime
tellraw @a [{"text":"MCFP: "},{"score":{"name":"fib_pgs3gb749vq9","objective":"mcfp_runtime"}}]
scoreboard players reset fib_pgs3gb749vq9 mcfp_runtime

# CLEAN
scoreboard players reset fib_bruh_x mcfp_runtime
scoreboard players reset fib_bruh_y mcfp_runtime
scoreboard players reset fib_bruh_z mcfp_runtime