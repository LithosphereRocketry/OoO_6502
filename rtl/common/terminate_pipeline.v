module terminate_pipeline(
        input [3:0] opcode,
        input [15:0] reg_base_val,
        input [7:0] flag_vals,
        input [7:0] offset,
        input [3:0] immediate,
        input instr_valid,
        output instr_ready,

        output [15:0] result_addr,
        output result_valid,
        input result_ready,
        output term_failed
    );

    wire [15:0] add = opcode[0] ? {12'b0, immediate}
                                : {8'b0, offset};
    assign result_addr = reg_base_val + add;

    assign instr_ready = result_ready;

    assign result_valid = (instr_valid & instr_ready) & (opcode[0] | (flag_vals[immediate[2:0]] == ~immediate[3]));

    assign term_failed = (instr_valid & instr_ready) & ~result_valid;

endmodule