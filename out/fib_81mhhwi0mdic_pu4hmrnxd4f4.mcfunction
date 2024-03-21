
# PRINT
tellraw @a [{"text":"MCFP: "},{"score":{"name":"fib_a","objective":"mcfp_runtime"}}]

# ASSIGN
scoreboard players operation fib_temp mcfp_runtime = fib_a mcfp_runtime

# ASSIGN
scoreboard players operation fib_a mcfp_runtime = fib_81mhhwi0mdic_b mcfp_runtime

# ASSIGN
scoreboard players operation fib_81mhhwi0mdic_pu4hmrnxd4f4_m95ewj7twmni mcfp_runtime = fib_temp mcfp_runtime
scoreboard players operation fib_81mhhwi0mdic_pu4hmrnxd4f4_m95ewj7twmni mcfp_runtime += fib_81mhhwi0mdic_b mcfp_runtime
scoreboard players operation fib_81mhhwi0mdic_b mcfp_runtime = fib_81mhhwi0mdic_pu4hmrnxd4f4_m95ewj7twmni mcfp_runtime
scoreboard players reset fib_81mhhwi0mdic_pu4hmrnxd4f4_m95ewj7twmni mcfp_runtime

# WHILE CONDITION
scoreboard players set fib_81mhhwi0mdic_pu4hmrnxd4f4_vxlsl1ludlgr mcfp_runtime 1000000000
scoreboard players set fib_81mhhwi0mdic_pu4hmrnxd4f4_w2v687j2n2ts mcfp_runtime 0
execute if score fib_a mcfp_runtime < fib_81mhhwi0mdic_pu4hmrnxd4f4_vxlsl1ludlgr mcfp_runtime run scoreboard players set fib_81mhhwi0mdic_pu4hmrnxd4f4_w2v687j2n2ts mcfp_runtime 1
scoreboard players reset fib_81mhhwi0mdic_pu4hmrnxd4f4_vxlsl1ludlgr mcfp_runtime

# WHILE REPEAT
execute if score should_break mcfp_runtime matches 1 run return 0
execute if score fib_81mhhwi0mdic_pu4hmrnxd4f4_w2v687j2n2ts mcfp_runtime matches 1 run execute if function mcfp:fib_81mhhwi0mdic_pu4hmrnxd4f4 run return 1
scoreboard players reset fib_81mhhwi0mdic_pu4hmrnxd4f4_w2v687j2n2ts mcfp_runtime