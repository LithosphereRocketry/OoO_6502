`include "constants.vh"

module middle_end(
    input clk,
    input rst,
    input [`RENAMED_OP_SZ-1:0] arith_instr,
    input [`RENAMED_OP_SZ-1:0] mem_instr,
    input [`RENAMED_OP_SZ-1:0] term_instr,

    input [2:0] valid_mask,
    input [8*3-1:0] arch_dest_regs,
    input [5*6-1:0] cmplt_regs,
    input [8*6-1:0] cmplt_vals,

    output [4*5-1:0] arch_dest_regs_out,
    output [5*3-1:0] ROB_entries_out,
    output [5*5-1:0] dest_regs_out,
    output [8*5-1:0] data_out,
    output [15:0] mem_addr,
    output mem_input_ready,
    output arith_valid,
    output mem_valid,
    output term_valid
);

wire [5*12-1:0] reg_read_addrs;
genvar i;
assign reg_read_addrs = {arith_instr[13 +: 20], mem_instr[13 +: 20], term_instr[13 +: 20]};

wire [8*12-1:0] reg_vals;

phys_reg_file _reg_file(
    .clk(clk),
    .rst(rst),

    .read_addrs(reg_read_addrs),
    .write_addrs(cmplt_regs),
    .write_vals(cmplt_vals),

    .read_vals(reg_vals)
);

arithmetic_pipeline _arith_pipe(
    .clk(clk),
    .opcode(arith_instr[`RENAMED_OP_SZ-4 +: 4]),
    .ROB_entry(arith_instr[4:0]),
    .dest_reg(arith_instr[33 +: 5]),
    .flag_reg(arith_instr[38 +: 5]),
    .op_a_val(reg_vals[8*9 +: 8]),
    .op_b_val(reg_vals[8*8 +: 8]),
    .flags_val(reg_vals[8*10 +: 8]),
    .arch_dest_regs(arch_dest_regs[8*2 +: 8]),

    .instr_valid(valid_mask[2]),

    .ROB_entry_out(ROB_entries_out[5*2 +: 5]),
    .dest_reg_out(dest_regs_out[5*4 +: 5]),
    .flag_reg_out(dest_regs_out[5*3 +: 5]),
    .result_val(data_out[8*4 +: 8]),
    .result_flags(data_out[8*3 +: 8]),
    .arch_dest_regs_out(arch_dest_regs_out[4*3 +: 8]),
    .output_valid(arith_valid)
);

memory_pipeline _mem_pipe(
    .clk(clk),
    .rst(rst),
    .opcode(mem_instr[`RENAMED_OP_SZ-4 +: 4]),
    .ROB_entry(mem_instr[4:0]),
    .base_val(reg_vals[8*5 +: 16]),
    .offset(reg_vals[8*4 +: 8]),
    .dest_reg(mem_instr[33 +: 5]),
    .data(reg_vals[8*7 +: 8]),
    .imm(mem_instr[5 +: 4]),
    .dest_arch_regs(arch_dest_regs[8 +: 8]),
    .input_valid(valid_mask[2]),
    .input_ready(mem_input_ready),

    .mem_addr(mem_addr),
    .mem_store(mem_store),
    .mem_dout(mem_dout),
    .mem_din(mem_din),

    .dest_reg_out(dest_regs_out[5*2 +: 5]),
    .data_out(data_out[8*2 +: 8]),
    .dest_arch_regs_out(arch_dest_regs_out[4*2 +: 8]),
    .ROB_entry_out(ROB_entries_out[5 +: 5]),
    .output_valid(mem_valid)
);

terminate_pipeline _term_pipe(
    .opcode(term_instr[`RENAMED_OP_SZ-4 +: 4]),
    .reg_base_val({reg_vals[8*3 +: 8], reg_vals[7:0]}),
    .flag_vals(reg_vals[8 +: 8]),
    .offset(reg_vals[8*2 +: 8]),
    .immediate(term_instr[3:0]),

    .result_addr(data_out[8*2-1:0]),
    .result_valid(term_valid)
);

assign ROB_entries_out[4:0] = ROB_entries[4:0];
assign arch_dest_regs_out[7:0] = arch_dest_regs[7:0];
assign dest_regs_out[9:0] = dest_regs[9:0];

endmodule