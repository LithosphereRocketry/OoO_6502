# Things that could be optimized / tweaked / added / otherwise todo

Figure out how to handle startup - could treat as an indirect jump?

Note: when handling issue of ALU ops, need to catch `bit` operations and pass
second operand as a value rather than looking up register address
