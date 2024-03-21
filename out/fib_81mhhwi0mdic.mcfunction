
# VAR
scoreboard players set fib_81mhhwi0mdic_b mcfp_runtime 1

# WHILE CONDITION
scoreboard players set fib_81mhhwi0mdic_4u512k0kqijq mcfp_runtime 1000000000
scoreboard players set fib_81mhhwi0mdic_9bmj619k5dm0 mcfp_runtime 0
execute if score fib_a mcfp_runtime < fib_81mhhwi0mdic_4u512k0kqijq mcfp_runtime run scoreboard players set fib_81mhhwi0mdic_9bmj619k5dm0 mcfp_runtime 1
scoreboard players reset fib_81mhhwi0mdic_4u512k0kqijq mcfp_runtime

# WHILE REPEAT
scoreboard players set should_break mcfp_runtime 0
execute if score fib_81mhhwi0mdic_9bmj619k5dm0 mcfp_runtime matches 1 run execute if function mcfp:fib_81mhhwi0mdic_pu4hmrnxd4f4 run return 1
scoreboard players reset fib_81mhhwi0mdic_9bmj619k5dm0 mcfp_runtime

# CLEAN
scoreboard players reset fib_81mhhwi0mdic_b mcfp_runtime