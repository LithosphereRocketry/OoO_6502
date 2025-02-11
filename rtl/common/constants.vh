// Flag register
`define FLAG_CARRY 0
`define FLAG_ZERO 1
`define FLAG_OVERFLOW 6
`define FLAG_NEGATIVE 7

// Microcode parameters (adjust as microcode gets bigger)
`define UCR_ADDR_WIDTH 9

// Pipeline/OoO parameters

`define PHYS_REGS 32
`define PR_ADDR_W $clog2(`PHYS_REGS)
// 4 opcode bits, 2 destination fields, 3 source fields
`define RENAMED_OP_SZ (4\ // opcode
                     + 2*`PR_ADDR_W\ // destinations
                     + 4*`PR_ADDR_W\ // sources
                     + 4\ // valid bits
                     + 4\ // immediate
                     + 5) // ROB entry 



// Register meanings
`define REG_PCH 4'h2
`define REG_PCL 4'h3