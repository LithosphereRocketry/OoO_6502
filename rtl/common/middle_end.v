`include "constants.vh"

module middle_end(
    input clk,
    input rst,
    input [`RENAMED_OP_SZ*3-1:0] instructions,
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
for(i = 0; i < 3; i = i + 1) begin
    assign reg_read_addrs[20*i +: 20] = instructions[`RENAMED_OP_SZ*i + 13 +: 20];
end

wire mem_out_ready;
wire [8*12-1:0] reg_vals;

assign mem_out_ready = 1;

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
    .opcode(instructions[`RENAMED_OP_SZ*3-4 +: 4]),
    .ROB_entry(instructions[`RENAMED_OP_SZ*2 +: 5]),
    .dest_reg(instructions[`RENAMED_OP_SZ*2+33 +: 5]),
    .flag_reg(instructions[`RENAMED_OP_SZ*2+38 +: 5]),
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
    .opcode(instructions[`RENAMED_OP_SZ*2-4 +: 4]),
    .ROB_entry(instructions[`RENAMED_OP_SZ +: 5]),
    .base_val(reg_vals[8*5 +: 16]),
    .offset(reg_vals[8*4 +: 8]),
    .dest_reg(instructions[`RENAMED_OP_SZ+33 +: 5]),
    .data(reg_vals[8*7 +: 8]),
    .imm(instructions[`RENAMED_OP_SZ+5 +: 4]),
    .dest_arch_regs(arch_dest_regs[8 +: 8]),
    .input_valid(valid_mask[2]),
    .input_ready(mem_input_ready),

    .mem_addr(mem_addr),
    .dest_reg_out(dest_regs_out[5*2 +: 5]),
    .data_out(data_out[8*2 +: 8]),
    .dest_arch_regs_out(arch_dest_regs_out[4*2 +: 8]),
    .ROB_entry_out(ROB_entries_out[5 +: 5]),
    .output_valid(mem_valid),
    .output_ready(mem_out_ready)
);

terminate_pipeline _term_pipe(
    .opcode(instructions[`RENAMED_OP_SZ-4 +: 4]),
    .reg_base_val({reg_vals[8*3 +: 8], reg_vals[7:0]}),
    .flag_vals(reg_vals[8 +: 8]),
    .offset(reg_vals[8*2 +: 8]),
    .immediate(instructions[3:0]),

    .result_addr(data_out[8*2-1:0]),
    .result_valid(term_valid)
);

assign ROB_entries_out[4:0] = ROB_entries[4:0];
assign arch_dest_regs_out[7:0] = arch_dest_regs[7:0];
assign dest_regs_out[9:0] = dest_regs[9:0];

endmodule