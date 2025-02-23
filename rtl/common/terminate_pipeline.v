module terminate_pipeline(
        input [3:0] opcode,
        input [15:0] reg_base_val,
        input [7:0] flag_vals,
        input [7:0] offset,
        input [3:0] immediate,
        input instr_valid,
        output instr_ready,
        input [4:0] ROB_entries,
        input [7:0] arch_dest_regs,
        input [9:0] phys_dest_regs,

        output [15:0] result_addr,
        output result_valid,
        input result_ready,
        output [4:0] ROB_entries_out,
        output [7:0] arch_dest_regs_out,
        output [9:0] phys_dest_regs_out
    );

    wire jump_happens = opcode[0] | (flag_vals[immediate[2:0]] == ~immediate[3]);

    wire [15:0] add = opcode[0] ? {12'b0, immediate}
                                : {{8{offset[7]}}, offset};
    // This is a bit of a hack - we know conditional jumps are always PC-relative
    // with a 1-byte immediate, so not doing them is equivalent to jumping to
    // base+1
    assign result_addr = reg_base_val + (jump_happens ? add : 1);

    assign instr_ready = result_ready;

    assign result_valid = (instr_valid & instr_ready);

    assign ROB_entries_out = ROB_entries;
    assign arch_dest_regs_out = result_valid ? arch_dest_regs : 8'b0;
    assign phys_dest_regs_out = result_valid ? phys_dest_regs : 10'b0;

endmodule