module cpu_ooo(
        input clk,
        input rst,

        output [15:0] addr_i,
        input [7:0] din_i,

        output [15:0] addr_d,
        output [7:0] dout_d,
        output wr_d,
        input [7:0] din_d
    );

    wire instr_valid = 0;
    wire instr_ready;

    wire [`RENAMED_OP_SZ-1:0] alu_op;
    wire alu_op_valid;
    wire alu_op_ready;

    wire [`RENAMED_OP_SZ-1:0] mem_op;
    wire mem_op_valid;
    wire mem_op_ready;

    wire [`RENAMED_OP_SZ-1:0] term_op;
    wire term_op_valid;
    wire term_op_ready;

    // wire [8*3-1:0] dispatch_

    frontend _frontend(
        .clk(clk),
        .rst(rst),
        
        .wakeup(1'b0),
        .instr(din_i),
        .instr_valid(instr_valid),
        .instr_ready(instr_ready),
        
        .cmplt_free_regs({30{1'b0}}),
        .cmplt_dest_arch({24{1'b0}}),
        .cmplt_dest_phys({30{1'b0}}),
        .ROB_entries({20{1'b0}}),
        
        // .decoded_old_aliases(),
        // .old_aliases_valid(),

        .alu_op(alu_op),
        .alu_op_valid(alu_op_valid),
        .alu_op_ready(alu_op_ready),

        .mem_op(mem_op),
        .mem_op_valid(mem_op_valid),
        .mem_op_ready(mem_op_ready),

        .term_op(term_op),
        .term_op_valid(term_op_valid),
        .term_op_ready(term_op_ready)
    );

    // currently, pipelines don't stall
    assign alu_op_ready = 1;
    assign mem_op_ready = 1;
    assign term_op_ready = 1;

    wire [4*5-1:0] complete_arch_regs;
    wire [5*3-1:0] complete_ROB_entries;
    wire complete_alu_valid, complete_mem_valid, complete_term_valid;

    middle_end _middle(
        .clk(clk),
        .rst(rst),

        .arith_instr(alu_op),
        .arith_valid(alu_op_valid),
        .mem_instr(mem_op),
        .mem_valid(mem_op_valid),
        .term_instr(term_op),
        .term_valid(term_op_valid),

        .mem_addr(addr_d),
        .mem_store(wr_d),
        .mem_dout(dout_d),
        .mem_din(din_d),

        .arch_dest_regs_out(complete_arch_regs)
    );

endmodule