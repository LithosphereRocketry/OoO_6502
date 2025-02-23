`include "constants.vh"

module middle_end(
    input clk,
    input rst,
    input [`RENAMED_OP_SZ-1:0] arith_instr,
    input arith_valid,
    input [`RENAMED_OP_SZ-1:0] mem_instr,
    input mem_valid,
    input [`RENAMED_OP_SZ-1:0] term_instr,
    input term_valid,
    output term_ready,

    output [15:0] mem_addr,
    output mem_store,
    output [7:0] mem_dout,
    input [7:0] mem_din,

    output [4*5-1:0] arch_dest_regs_out,
    output [`PR_ADDR_W*5-1:0] phys_dest_regs_out,
    output [5*3-1:0] ROB_entries_out,
    output complete_arith_valid,
    output complete_mem_valid,
    output complete_term_valid,
    input complete_term_ready,
    output complete_term_failed,
    output [15:0] term_address
);

wire [8*5-1:0] data_out;
wire [4:0] reg_writes;

wire [5*12-1:0] reg_read_addrs;
genvar i;
assign reg_read_addrs = {arith_instr[8 +: 20], mem_instr[8 +: 20], term_instr[8 +: 20]};

wire [8*12-1:0] reg_vals;

phys_reg_file _reg_file(
    .clk(clk),
    .rst(rst),

    .read_addrs(reg_read_addrs),
    .write_addrs(phys_dest_regs_out),
    .write_vals(data_out),
    .write_enable(reg_writes),

    .read_vals(reg_vals)
);

arithmetic_pipeline _arith_pipe(
    .clk(clk),
    .opcode(arith_instr[47:44]),
    .ROB_entry(arith_instr[42:38]),
    .dest_reg(arith_instr[28 +: 5]),
    .flag_reg(arith_instr[33 +: 5]),
    .op_a_val(reg_vals[8*9 +: 8]),
    .op_b_val(reg_vals[8*8 +: 8]),
    .flags_val(reg_vals[8*10 +: 8]),
    .arch_dest_regs(arith_instr[55:48]),
    .immediate(arith_instr[3:0]),

    .instr_valid(arith_valid),

    .ROB_entry_out(ROB_entries_out[5*2 +: 5]),
    .dest_reg_out(phys_dest_regs_out[5*4 +: 5]),
    .flag_reg_out(phys_dest_regs_out[5*3 +: 5]),
    .result_val(data_out[8*4 +: 8]),
    .result_flags(data_out[8*3 +: 8]),
    .arch_dest_regs_out(arch_dest_regs_out[4*3 +: 8]),
    .output_valid(complete_arith_valid)
);
assign reg_writes[4:3] = {2{complete_arith_valid}};

memory_pipeline _mem_pipe(
    .clk(clk),
    .rst(rst),
    .opcode(mem_instr[47:44]),
    .ROB_entry(mem_instr[42:38]),
    .base_val(reg_vals[8*5 +: 16]),
    .offset(reg_vals[8*4 +: 8]),
    .dest_reg(mem_instr[28 +: 5]),
    .data(reg_vals[8*7 +: 8]),
    .imm(mem_instr[3:0]),
    .dest_arch_regs(mem_instr[51:48]),
    .input_valid(mem_valid),
    .input_ready(mem_input_ready),

    .mem_addr(mem_addr),
    .mem_store(mem_store),
    .mem_dout(mem_dout),
    .mem_din(mem_din),

    .dest_reg_out(phys_dest_regs_out[5*2 +: 5]),
    .data_out(data_out[8*2 +: 8]),
    .dest_arch_regs_out(arch_dest_regs_out[4*2 +: 4]),
    .ROB_entry_out(ROB_entries_out[5 +: 5]),
    .output_valid(complete_mem_valid)
);
assign reg_writes[2] = complete_mem_valid;

wire [15:0] term_result_addr;
wire [4:0] term_ROB_entry;
wire [7:0] term_arch_dest_regs_out;
wire [9:0] term_phys_regs_out;
reg term_result_valid;

terminate_pipeline _term_pipe(
    .opcode(term_instr[47:44]),
    .reg_base_val({reg_vals[7:0], reg_vals[8*3 +: 8]}),
    .flag_vals(reg_vals[8 +: 8]),
    .offset(reg_vals[8*2 +: 8]),
    .immediate(term_instr[3:0]),
    .instr_valid(term_valid),
    .instr_ready(term_ready),
    //trying something
    .ROB_entries(term_instr[42:38]),
    .arch_dest_regs({term_instr[51:48], term_instr[55:52]}),
    .phys_dest_regs({term_instr[32:28], term_instr[37:33]}),

    .result_addr(term_result_addr),
    .result_valid(complete_term_valid),
    .result_ready(complete_term_ready),
    .term_failed(complete_term_failed),
    //trying something
    .ROB_entries_out(term_ROB_entry),
    .arch_dest_regs_out(term_arch_dest_regs_out),
    .phys_dest_regs_out(term_phys_regs_out)
);
assign reg_writes[1:0] = {2{term_result_valid}};

reg [15:0] term_result_addr_tmp;
reg [5:0] term_ROB_entry_tmp;
reg [8:0] term_arch_dest_regs_out_tmp;
reg [9:0] term_phys_regs_out_tmp;

assign data_out[8*2-1:0] = term_result_addr_tmp + 1;
assign ROB_entries_out[4:0] = term_ROB_entry_tmp;
assign arch_dest_regs_out[7:0] = term_arch_dest_regs_out_tmp;
assign phys_dest_regs_out[9:0] = term_phys_regs_out_tmp;

always @(posedge clk) begin
    term_result_addr_tmp <= term_result_addr;
    term_ROB_entry_tmp <= term_ROB_entry;
    term_arch_dest_regs_out_tmp <= term_arch_dest_regs_out;
    term_phys_regs_out_tmp <= term_phys_regs_out;
    term_result_valid <= complete_term_valid;
end

// assign ROB_entries_out[4:0] = term_instr[42:38];
// assign arch_dest_regs_out[7:0] = term_valid? term_instr[55:48] : 8'b0;
// assign phys_dest_regs_out[9:0] = term_valid ? term_instr[37:28] : 10'b0;

assign term_address = term_result_addr;

endmodule