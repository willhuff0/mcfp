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
execute if function mcfp:fib_81mhhwi0mdic run return 1

# CLEAN
scoreboard players reset fib_a mcfp_runtime
scoreboard players reset fib_temp mcfp_runtime