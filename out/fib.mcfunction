# Compiled by mcfp_dart 1.0

# RUNTIME SETUP

scoreboard objectives add mcfp_runtime dummy
scoreboard players reset * mcfp_runtime
scoreboard objectives setdisplay sidebar mcfp_runtime
scoreboard players set neg_one mcfp_runtime -1

# END RUNTIME SETUP
# WALKING SYNTAX TREE


# VAR
execute store result score fib_4j7nfdrmin44 mcfp_runtime run time query gametime
scoreboard players operation fib_start mcfp_runtime = fib_4j7nfdrmin44 mcfp_runtime

# VAR
scoreboard players set fib_a mcfp_runtime 0

# VAR
scoreboard players set fib_temp mcfp_runtime 0

# VAR
scoreboard players set fib_b mcfp_runtime 1

# WHILE CONDITION
scoreboard players set fib_ws2jw4ow9cek mcfp_runtime 1000000000
scoreboard players set fib_iue96riqqk97 mcfp_runtime 0
execute if score fib_a mcfp_runtime < fib_ws2jw4ow9cek mcfp_runtime run scoreboard players set fib_iue96riqqk97 mcfp_runtime 1
scoreboard players reset fib_ws2jw4ow9cek mcfp_runtime

# WHILE REPEAT
scoreboard players set should_break mcfp_runtime 0
execute if score fib_iue96riqqk97 mcfp_runtime matches 1 run execute if function mcfp:fib_fxrrcvl23wxp run return 1
scoreboard players reset fib_iue96riqqk97 mcfp_runtime

# VAR
execute store result score fib_6s92urndg1ne mcfp_runtime run time query gametime
scoreboard players operation fib_end mcfp_runtime = fib_6s92urndg1ne mcfp_runtime
scoreboard players operation fib_nw1s43tenpkg mcfp_runtime = fib_end mcfp_runtime
scoreboard players operation fib_nw1s43tenpkg mcfp_runtime -= fib_start mcfp_runtime
tellraw @a [{"text":"MCFP: "},{"score":{"name":"fib_nw1s43tenpkg","objective":"mcfp_runtime"}}]

# CLEAN
scoreboard players reset fib_start mcfp_runtime
scoreboard players reset fib_4j7nfdrmin44 mcfp_runtime
scoreboard players reset fib_a mcfp_runtime
scoreboard players reset fib_temp mcfp_runtime
scoreboard players reset fib_b mcfp_runtime
scoreboard players reset fib_end mcfp_runtime
scoreboard players reset fib_6s92urndg1ne mcfp_runtime
scoreboard players reset fib_nw1s43tenpkg mcfp_runtime