#!/usr/bin/python3

# Flag order (MSB-LSB):
# N V 1 B D I Z C

import sys
from microcode_asm import make_microcode, regs

regfile = [-1]*16
regfile[regs["zero"]] = 0
regfile[regs["one"]] = 1

memory = [-1] * (1<<16)

output = []

def regfile_to_str():
    return ("{"\
        + " ".join([
            f"{rname}:{regfile[reg]}"
        for rname, reg in regs.items()])
        + "}")

def write_reg(reg: int, val: int) -> None:
    # These registers won't be changed by microops so we ignore writes to them
    if reg not in [regs["zero"], regs["one"]]:
        regfile[reg] = val


def store(addr: int, val: int) -> bool:
    if addr == 0x4000:
        output.append(val)
    elif addr == 0x4100:
        return True
    elif addr < 1>>14:
        memory[addr] = val
    # above this range is ROM or undefined, so ignore it
    return False

def interpret_microop(op: int) -> tuple[bool, bool]:
    print(f"\t[micro] op: {hex(op)} regfile: {regfile_to_str()}")
    opcode = op >> 20
    fields = [(op >> (16-4*i)) & 0xF for i in range(5)]
    match opcode:
        case 0x1: # mov
            r_f_out, r_dest, r_f_in, r_a, _ = fields
            flags = r_f_in & ~0b10000010 # clear zero, negative
            result = regfile[r_a]
            if result & 0b10000000:
                flags |= 0b10000000 # set negative flag
            if result == 0:
                flags |= 0b00000010 # set zero flag
            write_reg(r_f_out, flags)
            write_reg(r_dest, result)
        case 0xD: # Memory operations
            subop, r_val, r_hb, r_lb, r_offs = fields
            if subop & 0b0100: # cut-carry
                addr = ((regfile[r_hb] << 8) |
                        ((regfile[r_lb] + regfile[r_offs]) & 0xFF))
            else: # no cut-carry
                addr = (((regfile[r_hb] << 8) | regfile[r_lb]) + regfile[r_offs])
            if subop & 0b1000: # store
                return False, store(addr, regfile[r_val])
                # this is the only place where our program can stop (by writing
                # to 0x4100)
            else: # load
                write_reg(r_val, memory[addr])
        case 0xF: # unconditional terminate
            r_hb, r_lb, _, _, _ = fields
            offset = op & 0xFFF
            addr = ((regfile[r_hb] << 8) | regfile[r_lb]) + offset
            write_reg(regs["pcl"], addr & 0xFF)
            write_reg(regs["pch"], (addr >> 8) & 0xFF)
            return True, False
        case _:
            print("Microop code", hex(opcode), "is not simulated!")
            exit(-1)
    return False, False

def interpret_macroop(offsets: dict[int, int], words: list[int]) -> bool:
    addr = (regfile[regs["pch"]] << 8) | regfile[regs["pcl"]]
    macroop = memory[addr]
    print(f"[MACRO] addr: {hex(addr)} opc: {hex(macroop)} regfile: {regfile_to_str()}")
    addr += 1
    write_reg(regs["pcl"], addr & 0xFF)
    write_reg(regs["pch"], (addr >> 8) & 0xFF)
    if macroop in offsets:
        mpc = offsets[macroop]
        while True:
            op_done, prog_done = interpret_microop(words[mpc])
            if prog_done:
                return False
            elif op_done:
                break
            mpc += 1
    else:
        print("Macroop", hex(macroop), "has no microcode!")
        exit(-1)
    return True

with open("6502.mic") as f:
    offsets, words = make_microcode(f)
    with open(sys.argv[1], "rb") as prog:
        prog_data = prog.read()
        memory[(1<<15) : (1<<16)] = prog_data
        # Manually handle the reset vector for now, until we git gud enough to
        # handle it with a unique microcode sequence
        write_reg(regs["pcl"], memory[0xFFFC])
        write_reg(regs["pch"], memory[0xFFFD])

        while interpret_macroop(offsets, words):
            pass
        
        if len(sys.argv) > 2:
            if len(output) > 256:
                print("Program terminated with too much output!")
                exit(-1)
            with open(sys.argv[2], "r") as verif:
                desired_output = [int(n, 16) for n in verif]
                if desired_output != output:
                    print("Wrong output! Expected:")
                    print(desired_output)
                    print("Got:")
                    print(output)
                    exit(-1)
                else:
                    print("Output correct!")
        else:
            print(output)
