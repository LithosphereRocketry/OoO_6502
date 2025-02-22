module memory_pipeline(
    input clk,
    input rst,
    input [3:0] opcode,
    input [4:0] ROB_entry,
    input [15:0] base_val,
    input [7:0] offset,
    input [`PR_ADDR_W-1:0] dest_reg,
    input [7:0] data,
    input [3:0] imm,
    input [3:0] dest_arch_regs,
    input input_valid,
    output input_ready,

    output reg [15:0] mem_addr,
    output reg mem_store,
    output reg [7:0] mem_dout,
    input [7:0] mem_din,

    output reg [`PR_ADDR_W-1:0] dest_reg_out,
    output [7:0] data_out,
    output reg [3:0] dest_arch_regs_out,
    output reg [4:0] ROB_entry_out,
    output reg output_valid
);

task reset; begin
    inflight_valid <= 0;
    dest_arch_regs_inflight <= 8'hxx;
    dest_reg_inflight <= {`PR_ADDR_W{1'bx}};
    ROB_entry_inflight <= 5'hxx;

    mem_store <= 0;
    mem_addr <= 16'hxxxx;
    mem_dout <= 8'hxx;

    dest_reg_out <= {`PR_ADDR_W{1'bx}};
    dest_arch_regs_out <= 8'hxx;
    output_valid <= 0;
    ROB_entry_out <= 5'hxx;
end endtask

reg [4:0] ROB_entry_inflight;
reg inflight_valid;
reg [7:0] dest_arch_regs_inflight;
reg [`PR_ADDR_W-1:0] dest_reg_inflight;

assign input_ready = 1; // no stalls here

assign data_out = mem_din;

integer lower_bits;

always @(posedge clk) if(rst) reset(); else begin
    // First clock cycle: calculate address
    if(imm[3]) begin
        lower_bits = base_val[7:0] + offset;
        mem_addr <= {base_val[15:8], lower_bits[7:0]};
    end
    else mem_addr <= base_val + offset;
    
    mem_store <= opcode[0] & input_valid & input_ready;
    dest_reg_inflight <= dest_reg;
    inflight_valid <= input_valid & input_ready;
    dest_arch_regs_inflight <= dest_arch_regs;
    ROB_entry_inflight <= ROB_entry;

    // Second clock cycle: write, or receive input from memory
    dest_reg_out <= dest_reg_inflight;
    dest_arch_regs_out <= dest_arch_regs;
    output_valid <= inflight_valid;
    ROB_entry_out <= ROB_entry_inflight;
end
endmodule