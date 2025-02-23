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

    reg instr_valid;
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

    wire [(2*`PR_ADDR_W+1)*4-1:0] decoded_old_aliases;
    wire decoded_old_aliases_valid;
    wire [2:0] rob_ready_ct;
    wire rob_entries_available;
    wire [5*4-1:0] next_ROB_entries;
    wire [6*`PR_ADDR_W-1:0] committed_free_regs;
    wire [4*5-1:0] complete_arch_regs;
    wire [`PR_ADDR_W*5-1:0] complete_phys_regs;

    assign rob_entries_available = rob_ready_ct == 4;

    // wire [8*3-1:0] dispatch_

    reg frontend_wakeup;

    frontend _frontend(
        .clk(clk),
        .rst(rst),
        
        // TODO: these valid/ready bits might need to have an added delay to
        // make up for the delay introduced by memory
        .wakeup(frontend_wakeup),
        .instr(din_i),
        .instr_valid(instr_valid), 
        .instr_ready(instr_ready),
        
        .cmplt_free_regs(committed_free_regs),
        .cmplt_dest_arch(complete_arch_regs),
        .cmplt_dest_phys(complete_phys_regs),
        .ROB_entries(next_ROB_entries),
        
        .decoded_old_aliases(decoded_old_aliases),
        .old_aliases_valid(decoded_old_aliases_valid),
        .old_aliases_ready(rob_entries_available),

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

    wire [5*3-1:0] complete_ROB_entries;
    wire complete_alu_valid, complete_mem_valid, complete_term_valid, complete_term_failed;

    always @(posedge clk) begin
        frontend_wakeup <= complete_term_valid;
        instr_valid <= complete_term_valid;
    end

    // assign term_op_ready = instr_ready;
    wire complete_term_wb_valid;
    
    middle_end _middle(
        .clk(clk),
        .rst(rst),

        .arith_instr(alu_op),
        .arith_valid(alu_op_valid),
        .mem_instr(mem_op),
        .mem_valid(mem_op_valid),
        .term_instr(term_op),
        .term_valid(term_op_valid),
        .term_ready(term_op_ready),

        .mem_addr(addr_d),
        .mem_store(wr_d),
        .mem_dout(dout_d),
        .mem_din(din_d),

        .arch_dest_regs_out(complete_arch_regs),
        .phys_dest_regs_out(complete_phys_regs),
        .ROB_entries_out(complete_ROB_entries),
        .complete_arith_valid(complete_alu_valid),
        .complete_mem_valid(complete_mem_valid),
        .complete_term_valid(complete_term_valid),
        .complete_term_wb_valid(complete_term_wb_valid),
        .complete_term_ready(instr_ready),
        .term_address(addr_i)
    );

    rob #(
        .DATA_WIDTH(11),
        .PUSH_WIDTH(4),
        .ELEMENTS(15)
    ) _rob (
        .clk(clk),
        .rst(rst),

        .din(decoded_old_aliases),
        .din_valid({4{decoded_old_aliases_valid}}),
        .din_ready_ct(rob_ready_ct),

        .dout(committed_free_regs),
        // output [$clog2(PUSH_WIDTH):0] dout_valid_ct,
        .dout_ready_ct(3'b011),

        .entry_nums(next_ROB_entries),

        .completed(complete_ROB_entries),
        .cmplt_valid({complete_alu_valid, complete_mem_valid, complete_term_wb_valid})
    );

endmodule