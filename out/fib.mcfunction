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

# VAR
scoreboard players set fib_b mcfp_runtime 1

# WHILE CONDITION
scoreboard players set fib_ul9bxhafejxk mcfp_runtime 1000000000
scoreboard players set fib_nvookfnascfg mcfp_runtime 0
execute if score fib_a mcfp_runtime < fib_ul9bxhafejxk mcfp_runtime run scoreboard players set fib_nvookfnascfg mcfp_runtime 1
scoreboard players reset fib_ul9bxhafejxk mcfp_runtime

# WHILE REPEAT
scoreboard players set should_break mcfp_runtime 0
execute if score fib_nvookfnascfg mcfp_runtime matches 1 run execute if function mcfp:fib_f94es0fi256g run return 1
scoreboard players reset fib_nvookfnascfg mcfp_runtime

# CLEAN
scoreboard players reset fib_a mcfp_runtime
scoreboard players reset fib_temp mcfp_runtime
scoreboard players reset fib_b mcfp_runtime