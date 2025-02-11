// Flag register
`define FLAG_CARRY 0
`define FLAG_ZERO 1
`define FLAG_OVERFLOW 6
`define FLAG_NEGATIVE 7

// Microcode parameters (adjust as microcode gets bigger)
`define UCR_ADDR_WIDTH 9

// Pipeline/OoO parameters

// Weird note here: PHYS_REGS must be at least 32 to not break things
// this is because *usually* the widest uop is 2 destinations 3 sources
// or 37 bits plus opcode at 32; except if PHYS_REGS is small, wr and only wr
// has to cram 4 sources, no destinations, and one cut-carry bit into the same
// space. There's better ways to deal with this, but I'm lazy.

// Also note that physical register 0xFFF... indicates a discarded value, and it
// will never be allocated.
`define PHYS_REGS 32
`define DISCARD_REG {$clog2(`PHYS_REGS){1'b1}}
// 4 opcode bits, 2 destination fields, 3 source fields
`define RENAMED_OP_SZ (4 + 2*$clog2(`PHYS_REGS) + 3*9)

// Register meanings
`define REG_PCH 4'h2
`define REG_PCL 4'h3