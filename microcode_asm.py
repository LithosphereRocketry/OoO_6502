#!/usr/bin/python3

import sys
import math
import typing
import more_itertools

print(sys.version)

# Make sure instructions start on a multiple of n words
align = 4

regnames = [
    "zero",
    "one",
    "pcl",
    "pch",
    "acc",
    "sp",
    "x",
    "y",
    "flag",
    "tmp0",
    "tmp1",
    "tmp2"
]

regs = {name: num for num, name in enumerate(regnames)}

opcode_hints: dict[int, str] = {}

# Basic parse step structure: take string, return value and remainder or None
# and unchanged string if conversion fails

def parse_int(args: str) -> tuple[int | None, str | None]:
    a_split = [a.strip() for a in args.split(",", 1)]
    if len(a_split) == 1:
        tail = None
    else:
        tail = a_split[1]
    return int(args, 0), tail

def parse_reg(args: str) -> tuple[int | None, str | None]:
    a_split = [a.strip() for a in args.split(",", 1)]
    if len(a_split) == 1:
        tail = None
    else:
        tail = a_split[1]
    
    if a_split[0] not in regs:
        return None, args
    else:
        return regs[a_split[0]], tail

def parse_pair(args: str) -> tuple[tuple[int, int] | None, str | None]:
    if args[0] != '{':
        return None, args
    
    a_split = [a.strip() for a in args[1:].split("}", 1)]
    if len(a_split) == 1 or a_split[1] == "":
        tail = None
    else:
        if a_split[1][0] != ',':
            print("Warning: ignoring missing comma in arguments", args)
            tail = a_split
        else:
            tail = a_split[1][1:].strip()
    
    internal = a_split[0]
    r1, internal = parse_reg(internal)
    if r1 is None:
        return None, args
    r2, internal = parse_reg(internal)
    if internal is not None:
        print("Warning: ignoring extra arguments to pair", args)
    return (r1, r2), tail

def parse_bit(args: str) -> tuple[tuple[int, int, bool] | None, str | None]:
    a_split = [a.strip() for a in args.split(",", 1)]
    if len(a_split) == 1:
        tail = None
    else:
        tail = a_split[1]

    a_operands = [a.strip() for a in a_split[0].split("@", 1)]
    if len(a_operands) != 2:
        return None, args
    regstr, bitstr = a_operands
    reg, _ = parse_reg(regstr)
    if bitstr[0] == '!':
        bit, _ = parse_int(bitstr[1:])
        inv = True
    else:
        bit, _ = parse_int(bitstr)
        inv = False
    if reg is None or bit is None:
        return None, args
    else:
        return (reg, bit, inv), tail


def encode_alu(opcode: int, dst: tuple[int, int], opa: tuple[int, int], opb: int) -> int:
    return (opcode << 20
            | dst[0] << 16
            | dst[1] << 12
            | opa[0] << 8
            | opa[1] << 4
            | opb)

def encode_bit(dst: int, opa: int, bit: int, inv: bool):
    return (0b1011 << 20
            | dst << 12
            | opa << 4
            | (0b1000 if inv else 0)
            | bit & 0b111)

def encode_mem(opcode: int, subop: int, srcdst: int, base: tuple[int, int], offset: int) -> int:
    return (opcode << 20
            | subop << 16
            | srcdst << 12
            | base[0] << 8
            | base[1] << 4
            | offset)

def encode_cterm(base: tuple[int, int], offset: int, reg: int, bit: int, inv: bool) -> int:
    return (0b1110 << 20
            | base[0] << 16
            | base[1] << 12
            | offset << 8
            | reg << 4
            | (0b1000 if inv else 0)
            | bit & 0b111)

def encode_term(base: tuple[int, int], offset: int) -> int:
    return (0b1111 << 20
            | base[0] << 16
            | base[1] << 12
            | offset)

def make_microcode(lines: typing.Iterable[str]) -> tuple[dict[int, int], list[int]]:
    words = []
    offsets = {}
    was_term = True
    for lnum, line in enumerate(lines):
        line_and_comment = line.split(";", 1)
        if len(line_and_comment) < 2:
            line_and_comment.append("")
        line_contents, comment = (s.strip() for s in line_and_comment)
        if line_contents == "":
            pass
        elif line_contents[0] == '@':
            if not was_term:
                raise Exception(f"Error: instruction at {lnum} not terminated!")
            opcode = int(line_contents[1:], 0)
            offsets[opcode] = len(words)
            opcode_hints[opcode] = comment
        else:
            uop, args = line_contents.split(None, 1)
            tail = args
            was_term = False
            match uop:
                case "add":
                    dest, tail = parse_pair(tail)
                    opa, tail = parse_pair(tail)
                    opb, tail = parse_reg(tail)
                    words.append(encode_alu(0b0000, dest, opa, opb))
                case "sub":
                    dest, tail = parse_pair(tail)
                    opa, tail = parse_pair(tail)
                    opb, tail = parse_reg(tail)
                    words.append(encode_alu(0b0001, dest, opa, opb))
                case "cmp":
                    dest, tail = parse_reg(tail)
                    opa, tail = parse_pair(tail)
                    opb, tail = parse_reg(tail)
                    words.append(encode_alu(0b0010, (dest, 0), opa, opb))
                case "and":
                    dest, tail = parse_pair(tail)
                    opa, tail = parse_pair(tail)
                    opb, tail = parse_reg(tail)
                    words.append(encode_alu(0b0011, dest, opa, opb))
                case "or":
                    dest, tail = parse_pair(tail)
                    opa, tail = parse_pair(tail)
                    opb, tail = parse_reg(tail)
                    words.append(encode_alu(0b0100, dest, opa, opb))
                case "xor":
                    dest, tail = parse_pair(tail)
                    opa, tail = parse_pair(tail)
                    opb, tail = parse_reg(tail)
                    words.append(encode_alu(0b0101, dest, opa, opb))
                case "sl":
                    dest, tail = parse_pair(tail)
                    opa, tail = parse_pair(tail)
                    words.append(encode_alu(0b0110, dest, opa, 0))
                case "lsr":
                    dest, tail = parse_pair(tail)
                    opa, tail = parse_pair(tail)
                    words.append(encode_alu(0b0111, dest, opa, 0))
                case "rol":
                    dest, tail = parse_pair(tail)
                    opa, tail = parse_pair(tail)
                    words.append(encode_alu(0b1000, dest, opa, 0))
                case "ror":
                    dest, tail = parse_pair(tail)
                    opa, tail = parse_pair(tail)
                    words.append(encode_alu(0b1001, dest, opa, 0))
                case "bit":
                    dest, tail = parse_reg(tail)
                    (reg, bit, inv), tail = parse_bit(tail)
                    words.append(encode_bit(dest, reg, bit, inv))
                case "ld":
                    dest, tail = parse_reg(tail)
                    base_addr, tail = parse_pair(tail)
                    offset, tail = parse_reg(tail)
                    words.append(encode_mem(0b1100, 0b0000, dest, base_addr, offset))
                case "ldc":
                    dest, tail = parse_reg(tail)
                    base_addr, tail = parse_pair(tail)
                    offset, tail = parse_reg(tail)
                    words.append(encode_mem(0b1100, 0b1000, dest, base_addr, offset))
                case "st":
                    src, tail = parse_reg(tail)
                    base_addr, tail = parse_pair(tail)
                    offset, tail = parse_reg(tail)
                    words.append(encode_mem(0b1101, 0b0000, src, base_addr, offset))
                case "stc":
                    src, tail = parse_reg(tail)
                    base_addr, tail = parse_pair(tail)
                    offset, tail = parse_reg(tail)
                    words.append(encode_mem(0b1101, 0b1000, src, base_addr, offset))
                case "cterm":
                    base_addr, tail = parse_pair(tail)
                    offset, tail = parse_reg(tail)
                    (reg, bit, inv), tail = parse_bit(tail)
                    words.append(encode_cterm(base_addr, offset, reg, bit, inv))
                    while len(words) % align != 0:
                        words.append(0)
                    was_term = True
                case "term":
                    base_addr, tail = parse_pair(tail)
                    offset, tail = parse_int(tail)
                    words.append(encode_term(base_addr, offset))
                    while len(words) % align != 0:
                        words.append(0)
                    was_term = True
                case _:
                    print("Unrecognized uopcode", uop)
                    exit(-1)
            if tail is not None:
                print("Ignoring extra arguments", tail)
    return offsets, words
if __name__ == "__main__":
    with open(sys.argv[1]) as f:
        offsets, words = make_microcode(f)
        uop_addr_bits = math.ceil(math.log2(len(words)))
        print("Bits in microop address:", uop_addr_bits)
        # use 0xFFFFF... as a placeholder value, since this should never be the
        # start address
        uop_rom = [(1 << uop_addr_bits)-1] * 256
        for macroop, offset in offsets.items():
            uop_rom[macroop] = offset

        hex_width = math.ceil(uop_addr_bits/4)
        with open(sys.argv[2], "w") as f_offsets:
            f_offsets.writelines(f"{val:0{hex_width}x}\n" for val in uop_rom)
        with open(sys.argv[3], "w") as f_microops:
            f_microops.writelines("".join(f"{val:06x}" for val in row) + "\n"
                                 for row in more_itertools.ichunked(words, align))