#!/usr/bin/python

import sys
import typing

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
    return (0b1100 << 20
            | dst << 12
            | opa << 4
            | (0b1000 if inv else 0)
            | bit & 0b111)

def encode_mem(subop: int, srcdst: int, base: tuple[int, int], offset: int) -> int:
    return (0b1101 << 20
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
    for line in lines:
        line_contents = line.split(";")[0].strip()
        if line_contents == "":
            pass
        elif line_contents[0] == '@':
            offsets[int(line_contents[1:], 0)] = len(words)
        else:
            uop, args = line_contents.split(None, 1)
            tail = args
            match uop:
                case "add":
                    dest, tail = parse_pair(tail)
                    opa, tail = parse_pair(tail)
                    opb, tail = parse_reg(tail)
                    words.append(encode_alu(0b0000, dest, opa, opb))
                case "mov":
                    dest, tail = parse_pair(tail)
                    opa, tail = parse_pair(tail)
                    words.append(encode_alu(0b0001, dest, opa, 0))
                case "sub":
                    dest, tail = parse_pair(tail)
                    opa, tail = parse_pair(tail)
                    opb, tail = parse_reg(tail)
                    words.append(encode_alu(0b0010, dest, opa, opb))
                case "cmp":
                    dest, tail = parse_reg(tail)
                    opa, tail = parse_pair(tail)
                    opb, tail = parse_reg(tail)
                    words.append(encode_alu(0b0011, (dest, 0), opa, opb))
                case "bit":
                    dest, tail = parse_reg(tail)
                    (reg, bit, inv), tail = parse_bit(tail)
                    words.append(encode_bit(dest, reg, bit, inv))
                case "ld":
                    dest, tail = parse_reg(tail)
                    base_addr, tail = parse_pair(tail)
                    offset, tail = parse_reg(tail)
                    words.append(encode_mem(0b0000, dest, base_addr, offset))
                case "ldc":
                    dest, tail = parse_reg(tail)
                    base_addr, tail = parse_pair(tail)
                    offset, tail = parse_reg(tail)
                    words.append(encode_mem(0b0100, dest, base_addr, offset))
                case "st":
                    src, tail = parse_reg(tail)
                    base_addr, tail = parse_pair(tail)
                    offset, tail = parse_reg(tail)
                    words.append(encode_mem(0b1000, src, base_addr, offset))
                case "stc":
                    src, tail = parse_reg(tail)
                    base_addr, tail = parse_pair(tail)
                    offset, tail = parse_reg(tail)
                    words.append(encode_mem(0b1100, src, base_addr, offset))
                case "cterm":
                    base_addr, tail = parse_pair(tail)
                    offset, tail = parse_reg(tail)
                    (reg, bit, inv), tail = parse_bit(tail)
                    words.append(encode_cterm(base_addr, offset, reg, bit, inv))
                case "term":
                    base_addr, tail = parse_pair(tail)
                    offset, tail = parse_int(tail)
                    words.append(encode_term(base_addr, offset))
                case _:
                    print("Unrecognized uopcode", uop)
                    exit(-1)
            if tail is not None:
                print("Ignoring extra arguments", tail)
    return offsets, words
if __name__ == "__main__":
    with open(sys.argv[1]) as f:
        offsets, words = make_microcode(f)
        print(offsets)
        for word in words:
            print(hex(word))
                