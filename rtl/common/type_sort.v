// Only supports issuing one per type for now - TODO add more later

// TODO: WRONG: needs to act on physical rather than logical instructions

module type_sort_cell (
        input [23:0] instr_in,
        input instr_valid,

        input was_terminated,
        output is_terminated,

        input instr_alu_ready,
        input instr_mem_ready,
        input instr_term_ready,

        input had_alu,
        input had_mem,
        input had_term,

        output has_alu,
        output has_mem,
        output has_term,

        output is_alu,
        output is_mem,
        output is_term,

        output used
    );

    wire [3:0] opcode = instr_in[23:20];

    wire op_is_alu = instr_valid & opcode[3:2] != 2'b11;
    assign is_alu = ~was_terminated & ~had_alu & op_is_alu;
    assign has_alu = had_alu | is_alu;

    wire is_nop = op_is_alu & instr_in[19:12] == 8'h00; // ALU op with no dest = nop

    wire op_is_mem = instr_valid & opcode[3:1] == 3'b110;
    assign is_mem = ~was_terminated & ~had_mem & op_is_mem;
    assign has_mem = had_mem | is_mem;

    wire op_is_term = instr_valid & opcode[3:1] == 3'b111;
    assign is_term = ~was_terminated & ~had_term & op_is_term;
    assign has_term = had_term | is_term;
    assign is_terminated = was_terminated | op_is_term;
    // even if stalled, still stop searching at terminate instructions

    assign used = is_nop | (instr_alu_ready & is_alu)
                         | (instr_mem_ready & is_mem)
                         | (instr_term_ready & is_term);
endmodule

module type_sort #(parameter FETCH_WIDTH = 4) (
        input [FETCH_WIDTH*24-1:0] instr_in,
        input [FETCH_WIDTH-1:0] instr_valid,
        output [FETCH_WIDTH-1:0] instr_used,

        output [23:0] instr_alu,
        output instr_alu_valid,
        input instr_alu_ready,
        output [23:0] instr_mem,
        output instr_mem_valid,
        input instr_mem_ready,
        output [23:0] instr_term,
        output instr_term_valid,
        input instr_term_ready,
        output terminate
    );

    localparam FS_ADDR_W = $clog2(FETCH_WIDTH);

    wire [FETCH_WIDTH-2:0] tmp_has_alu, tmp_has_mem, tmp_has_term, tmp_terminated;
    wire [FETCH_WIDTH-1:0] is_alu_mask, is_mem_mask, is_term_mask, is_nop_mask;

    type_sort_cell sort_cells [FETCH_WIDTH-1:0] (
        .instr_in(instr_in),
        .instr_valid(instr_valid),

        .instr_alu_ready(instr_alu_ready),
        .instr_mem_ready(instr_mem_ready),
        .instr_term_ready(instr_term_ready),

        .was_terminated({1'b0, tmp_terminated}),
        .is_terminated({tmp_terminated, terminate}),

        .used(instr_used),

        .had_alu({1'b0, tmp_has_alu}),
        .is_alu(is_alu_mask),
        .has_alu({tmp_has_alu, instr_alu_valid}),

        .had_mem({1'b0, tmp_has_mem}),
        .is_mem(is_mem_mask),
        .has_mem({tmp_has_mem, instr_mem_valid}),

        .had_term({1'b0, tmp_has_term}),
        .is_term(is_term_mask),
        .has_term({tmp_has_term, instr_term_valid})
    );

    wire [FS_ADDR_W-1:0] ind_alu, ind_mem, ind_term;
    priority_enc #(FETCH_WIDTH) ind_encoder [2:0] (
        .in({is_alu_mask, is_mem_mask, is_term_mask}),
        .out({ind_alu, ind_mem, ind_term})
    );

    assign instr_alu = instr_in[ind_alu*24 +: 24];
    assign instr_mem = instr_in[ind_mem*24 +: 24];
    assign instr_term = instr_in[ind_term*24 +: 24];

endmodule