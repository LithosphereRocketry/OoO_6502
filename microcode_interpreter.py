#!/usr/bin/python3

# Flag order (MSB-LSB):
# N V 1 B D I Z C

import sys
from microcode_asm import make_microcode, regs, regnames, opcode_hints

regfile = [-1]*16
regfile[regs["zero"]] = 0
regfile[regs["one"]] = 1
regfile[regs["flag"]] = 0b00100000

memory = [-1] * (1<<16)

output = []

def regfile_to_str():
    return ("{"\
        + " ".join([
            f"{rname}:{hex(regfile[reg])}"
        for rname, reg in regs.items()])
        + "}")


def read_reg(reg: int) -> int:
    val = regfile[reg]
    if val not in range(0, 256):
        print(f"Used undefined value in regster {regnames[reg]}!")
        exit(-1)
    return val

def write_reg(reg: int, val: int) -> None:
    # These registers won't be changed by microops so we ignore writes to them
    if reg not in [regs["zero"], regs["one"]]:
        regfile[reg] = val

def load(addr: int) -> int:
    if addr not in range(0, 65536):
        print(f"Error, tried to read from undefined address")
        exit(-1)
    val = memory[addr]
    if val not in range(0, 256):
        print(f"Loaded undefined value from address {addr:04x}!")
        exit(-1)
    return val
    


def store(addr: int, val: int) -> bool:
    if addr not in range(0, 65536):
        print(f"Error, tried to write to undefined address")
        exit(-1)
    elif val not in range(0, 256):
        print(f"Error, tried to write undefined data at addr {addr:04x}")
        exit(-1)
    if addr == 0x4000:
        output.append(val)
    elif addr == 0x4100:
        return True
    elif addr < 1<<14:
        memory[addr] = val
    else:
        # above this range is ROM or undefined, so error
        print(f"Error, tried to write to undefined address {addr:04x}")
        exit(-1)

micro_count = 0
macro_count = 0
memop_count = 0

def interpret_microop(op: int) -> tuple[bool, bool]:
    global micro_count, memop_count
    micro_count += 1
    print(f"\t[micro] op: {hex(op)} regfile: {regfile_to_str()}")
    opcode = op >> 20
    fields = [(op >> (16-4*i)) & 0xF for i in range(5)]
    match opcode:
        case 0x0: # add
            r_f_out, r_dest, r_f_in, r_a, r_b = fields
            flags = read_reg(r_f_in) & ~0b11000011 # clear carry, zero, overflow, negative
            result = read_reg(r_a) + read_reg(r_b) + (read_reg(r_f_in) & 0b1)
            print(result)
            if (read_reg(r_a) ^ result) & (read_reg(r_b) ^ result) & 0b10000000:
                flags |= 0b01000000 # Set overflow flag
            if result > 0xFF:
                result &= 0xFF
                flags |= 0b00000001 # Handle carry-out
            if result & 0b10000000:
                flags |= 0b10000000 # set negative flag
            if result == 0:
                flags |= 0b00000010 # set zero flag
            write_reg(r_f_out, flags)
            write_reg(r_dest, result)
        case 0x1: # sub
            r_f_out, r_dest, r_f_in, r_a, r_b = fields
            flags = read_reg(r_f_in) & ~0b11000011 # clear carry, zero, overflow, negative
            result = read_reg(r_a) + ((~read_reg(r_b)) & 0xFF) + (read_reg(r_f_in) & 0b1)

            if (read_reg(r_a) ^ result) & ~(read_reg(r_b) ^ result) & 0b10000000:
                flags |= 0b01000000 # Set overflow flag
            if result > 0xFF:
                result &= 0xFF
                flags |= 0b1 # Handle carry
            if result & 0b10000000:
                flags |= 0b10000000 # set negative flag
            if result == 0:
                flags |= 0b00000010 # set zero flag
            write_reg(r_f_out, flags)
            write_reg(r_dest, result)
        case 0x2: # cmp
            r_f_out, _, r_f_in, r_a, r_b = fields
            flags = read_reg(r_f_in) & ~0b10000011 # clear carry, zero, negative
            result = read_reg(r_a) + ((~read_reg(r_b)) & 0xFF) + 1

            if result > 0xFF:
                result &= 0xFF
                flags |= 0b1 # Handle carry
            if result & 0b10000000:
                flags |= 0b10000000 # set negative flag
            if result == 0:
                flags |= 0b00000010 # set zero flag
            write_reg(r_f_out, flags)
        case 0x3: # and
            r_f_out, r_dest, r_f_in, r_a, r_b = fields
            result = read_reg(r_a) & read_reg(r_b)
            flags = read_reg(r_f_in) & ~0b10000010 # clear zero, negative
            if result & 0b10000000:
                flags |= 0b10000000 # set negative flag
            if result == 0:
                flags |= 0b00000010 # set zero flag
            write_reg(r_f_out, flags)
            write_reg(r_dest, result)
        case 0x4: # or
            r_f_out, r_dest, r_f_in, r_a, r_b = fields
            result = read_reg(r_a) | read_reg(r_b)
            flags = read_reg(r_f_in) & ~0b10000010 # clear zero, negative
            if result & 0b10000000:
                flags |= 0b10000000 # set negative flag
            if result == 0:
                flags |= 0b00000010 # set zero flag
            write_reg(r_f_out, flags)
            write_reg(r_dest, result)
        case 0x5: # xor
            r_f_out, r_dest, r_f_in, r_a, r_b = fields
            result = read_reg(r_a) ^ read_reg(r_b)
            flags = read_reg(r_f_in) & ~0b10000010 # clear zero, negative
            if result & 0b10000000:
                flags |= 0b10000000 # set negative flag
            if result == 0:
                flags |= 0b00000010 # set zero flag
            write_reg(r_f_out, flags)
            write_reg(r_dest, result)
        case 0x6: # sl
            r_f_out, r_dest, r_f_in, r_a, _ = fields
            result = (read_reg(r_a) << 1) & 0xFF
            flags = read_reg(r_f_in) & ~0b10000011 # clear carry, zero, negative
            if read_reg(r_a) & 0b10000000:
                flags |= 0b00000001 # Handle carry-out
            if result & 0b10000000:
                flags |= 0b10000000 # set negative flag
            if result == 0:
                flags |= 0b00000010 # set zero flag
            write_reg(r_f_out, flags)
            write_reg(r_dest, result)
        case 0x7: # lsr
            r_f_out, r_dest, r_f_in, r_a, _ = fields
            result = read_reg(r_a) >> 1
            flags = read_reg(r_f_in) & ~0b10000011 # clear carry, zero, negative
            if read_reg(r_a) & 0b00000001:
                flags |= 0b00000001 # Handle carry-out
            if result & 0b10000000:
                flags |= 0b10000000 # set negative flag
            if result == 0:
                flags |= 0b00000010 # set zero flag
            write_reg(r_f_out, flags)
            write_reg(r_dest, result)
        case 0x8: # rol
            r_f_out, r_dest, r_f_in, r_a, _ = fields
            result = (read_reg(r_a) << 1) & 0xFF
            flags = read_reg(r_f_in) & ~0b10000011 # clear carry, zero, negative
            if read_reg(r_f_in) & 0b00000001:
                result |= 0b1 # Handle rotate
            if read_reg(r_a) & 0b10000000:
                flags |= 0b00000001 # Handle carry-out
            if result & 0b10000000:
                flags |= 0b10000000 # set negative flag
            if result == 0:
                flags |= 0b00000010 # set zero flag
            write_reg(r_f_out, flags)
            write_reg(r_dest, result)
        case 0x9: # ror
            r_f_out, r_dest, r_f_in, r_a, _ = fields
            result = read_reg(r_a) >> 1
            flags = read_reg(r_f_in) & ~0b10000011 # clear carry, zero, negative
            if read_reg(r_f_in) & 0b00000001:
                result |= 0b10000000 # Handle rotate
            if read_reg(r_a) & 0b00000001:
                flags |= 0b00000001 # Handle carry-out
            if result & 0b10000000:
                flags |= 0b10000000 # set negative flag
            if result == 0:
                flags |= 0b00000010 # set zero flag
            write_reg(r_f_out, flags)
            write_reg(r_dest, result)
        case 0xB: # bit
            _, r_dest, _, r_a, bitmask = fields
            inv = (bitmask & 0b1000) != 0
            bit = bitmask & 0b111
            if inv:
                write_reg(r_dest, r_a & ~(1 << bit))
            else:
                write_reg(r_dest, r_a | (1 << bit))
        case 0xC: # ld
            memop_count += 1
            subop, r_val, r_hb, r_lb, r_offs = fields
            if subop & 0b1000: # cut-carry
                addr = ((read_reg(r_hb) << 8) |
                        ((read_reg(r_lb) + read_reg(r_offs)) & 0xFF))
            else: # no cut-carry
                addr = (((read_reg(r_hb) << 8) | read_reg(r_lb)) + read_reg(r_offs))
            write_reg(r_val, load(addr))
        case 0xD: # st
            memop_count += 1
            subop, r_val, r_hb, r_lb, r_offs = fields
            if subop & 0b1000: # cut-carry
                addr = ((read_reg(r_hb) << 8) |
                        ((read_reg(r_lb) + read_reg(r_offs)) & 0xFF))
            else: # no cut-carry
                addr = (((read_reg(r_hb) << 8) | read_reg(r_lb)) + read_reg(r_offs))
            return False, store(addr, read_reg(r_val))
            # this is the only place where our program can stop (by writing
            # to 0x4100)
        case 0xE: # conditional terminate
            r_hb, r_lb, r_offs, r_cond, bitmask = fields
            print(bitmask)
            inv = (bitmask & 0b1000) != 0
            bit = bitmask & 0b111
            cond_hit = (read_reg(r_cond) & (1 << bit)) != 0
            print(cond_hit)
            print(inv)
            if inv:
                cond_hit = not cond_hit
            print(cond_hit)
            if cond_hit:
                # Convert offset to two's complement
                offset = ((read_reg(r_offs) + 128) & 0xFF) - 128
                # offsets are relative to the last byte of the instruction
                addr = ((read_reg(r_hb) << 8) | read_reg(r_lb)) + 1 + offset
                write_reg(regs["pcl"], addr & 0xFF)
                write_reg(regs["pch"], (addr >> 8) & 0xFF)
                return True, False
        case 0xF: # unconditional terminate
            r_hb, r_lb, _, _, _ = fields
            offset = op & 0xFFF
            addr = ((read_reg(r_hb) << 8) | read_reg(r_lb)) + offset 
            write_reg(regs["pcl"], addr & 0xFF)
            write_reg(regs["pch"], (addr >> 8) & 0xFF)
            return True, False
        case _:
            print("Microop code", hex(opcode), "is not simulated!")
            exit(-1)
    return False, False

def interpret_macroop(offsets: dict[int, int], words: list[int], seq) -> bool:
    global macro_count
    macro_count += 1
    if macro_count > 1e6:
        print("Interpreter timed out after 1M operations")
        return False
    addr = (regfile[regs["pch"]] << 8) | regfile[regs["pcl"]]
    macroop = load(addr)

    if seq is not None:
        line = seq.readline()
        vals = [addr+1, macroop, regfile[regs["acc"]], regfile[regs["sp"]], regfile[regs["x"]], regfile[regs["y"]]]
        should_vals = [int(s.replace("xx", "-1"), 16) for s in line.split()]
        if any(i != j for i, j in zip(vals, should_vals)):
            print(f"Error! expected:")
            print([hex(i) for i in should_vals])
            print(f"got:")
            print([hex(i) for i in vals])
            exit(-1)
    opstr = opcode_hints[macroop] if macroop in opcode_hints else "???"
    print(f"[MACRO] addr: {hex(addr)} opc: {hex(macroop)} \"{opstr}\" regfile: {regfile_to_str()}")
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

        seq_file = None
        if len(sys.argv) > 3:
            seq_file = open(sys.argv[3])

        while interpret_macroop(offsets, words, seq_file):
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
                    print("Executed", macro_count, "instructions,",
                                      micro_count, "microops,",
                                      memop_count, "data accesses")
        else:
            print(output)
