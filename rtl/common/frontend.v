module frontend #(
    parameter FETCH_WIDTH = 4
) (
        input clk,
        input rst,

        input wakeup,
        input [7:0] instr,
        input instr_valid,
        output instr_ready,

        input [6*`PR_ADDR_W-1:0] cmplt_free_regs,
        input [5*4-1:0] cmplt_dest_arch,
        input [5*`PR_ADDR_W-1:0] cmplt_dest_phys,
        input [19:0] ROB_entries,

        output [2*`PR_ADDR_W*FETCH_WIDTH-1:0] decoded_old_aliases,
        output old_aliases_valid,
        input old_aliases_ready,

        output [`RENAMED_OP_SZ-1:0] alu_op,
        output alu_op_valid,
        input alu_op_ready,

        output [`RENAMED_OP_SZ-1:0] mem_op,
        output mem_op_valid,
        input mem_op_ready,

        output [`RENAMED_OP_SZ-1:0] term_op,
        output term_op_valid,
        input term_op_ready
    );

    wire microops_ready;
    wire [FETCH_WIDTH*24-1:0] microops;
    wire do_microops;
    
    uop_fetch #(FETCH_WIDTH) fetch (
        .clk(clk),
        .rst(rst),
        .fetch(wakeup & instr_valid & instr_ready),
        .macroop_in(instr),
        .microops_ready(microops_ready & do_microops),
        .microops(microops)
    );

    assign instr_ready = microops_ready; // TODO is this right?

    wire [`RENAMED_OP_SZ*FETCH_WIDTH-1:0] decoded_instrs;
    wire [8*FETCH_WIDTH-1:0] decoded_arch_regs;
    wire [FETCH_WIDTH-1:0] decoded_instrs_ready, decoded_instrs_valid;
    wire decoder_ready;

    decoder #(FETCH_WIDTH) _decoder(
        .clk(clk),
        .rst(rst),

        .cmplt_free_regs(cmplt_free_regs),
        .cmplt_dest_regs(cmplt_dest_arch),
        .ROB_entries_in(ROB_entries),

        .logical_instrs(microops),
        .logical_instrs_valid(do_microops),
        .logical_instrs_ready(microops_ready),

        .decoded_instrs(decoded_instrs),
        .decoded_arch_regs(decoded_arch_regs),
        .decoded_old_aliases(decoded_old_aliases),
        .old_aliases_valid(old_aliases_valid),
        .decoded_instrs_ready(decoded_instrs_ready),
        .decoded_instrs_valid(decoded_instrs_valid)
    );

    genvar g;
    wire [FETCH_WIDTH-1:0] op_is_term;
    for(g = 0; g < FETCH_WIDTH; g = g + 1)
            assign op_is_term[g] = decoded_instrs[g*`RENAMED_OP_SZ + 45 +: 3] == 3'b111;
    
    wire issuing_term = 
            |(op_is_term & decoded_instrs_ready & decoded_instrs_valid);
    reg running;
    assign do_microops = running ? ~issuing_term : wakeup;


    wire sort_alu_valid, sort_mem_valid, sort_term_valid;
    wire sort_alu_ready, sort_mem_ready, sort_term_ready;
    wire [`RENAMED_OP_SZ-1:0] sort_alu_op, sort_mem_op, sort_term_op;
    wire [3:0] decoded_instrs_used;
    assign decoded_instrs_ready = decoded_instrs_used & {4{old_aliases_ready}};
    type_sort #(FETCH_WIDTH) sorter(
        .instr_in(decoded_instrs),
        .instr_valid(decoded_instrs_valid),
        .instr_used(decoded_instrs_used),

        .instr_alu(sort_alu_op),
        .instr_alu_valid(sort_alu_valid),
        .instr_alu_ready(sort_alu_ready),
        .instr_mem(sort_mem_op),
        .instr_mem_valid(sort_mem_valid),
        .instr_mem_ready(sort_mem_ready),
        .instr_term(sort_term_op),
        .instr_term_valid(sort_term_valid),
        .instr_term_ready(sort_term_ready)
    );

    integer i;
    reg [`PHYS_REGS-3:0] cmplt_dest_mask; // combinational
    reg [`PR_ADDR_W-1:0] cmplt_dest_tmp; // combinational
    always @* begin
        cmplt_dest_mask = 0;
        for(i = 0; i < 5; i = i + 1) begin
            cmplt_dest_tmp = cmplt_dest_phys[i*`PR_ADDR_W +: `PR_ADDR_W];
            if(cmplt_dest_tmp >= 2) cmplt_dest_mask[cmplt_dest_tmp-2] = 1;
        end
    end

    issue_buffer_ooo #(
        .DATA_WIDTH(`RENAMED_OP_SZ),
        .PUSH_WIDTH(1),
        .ELEMENTS(4)
    ) arithmetic_buffer(
        .clk(clk),
        .rst(rst),

        .din(sort_alu_op),
        .din_ready_ct(sort_alu_ready),
        .din_valid_ct(sort_alu_valid),

        .done_flags(cmplt_dest_mask),

        .dout(alu_op),
        .dout_valid(alu_op_valid),
        .dout_ready(alu_op_ready)
    );

    issue_buffer_seq #(
        .DATA_WIDTH(`RENAMED_OP_SZ),
        .ELEMENTS(4)
    ) mem_buffer(
        .clk(clk),
        .rst(rst),

        .din(sort_mem_op),
        .din_ready(sort_mem_ready),
        .din_valid(sort_mem_valid),

        .done_flags(cmplt_dest_mask),

        .dout(mem_op),
        .dout_valid(mem_op_valid),
        .dout_ready(mem_op_ready)
    );

    issue_buffer_seq #(
        .DATA_WIDTH(`RENAMED_OP_SZ),
        .ELEMENTS(4)
    ) term_buffer(
        .clk(clk),
        .rst(rst),

        .din(sort_term_op),
        .din_ready(sort_term_ready),
        .din_valid(sort_term_valid),

        .done_flags(cmplt_dest_mask),

        .dout(term_op),
        .dout_valid(term_op_valid),
        .dout_ready(term_op_ready)
    );

    task reset; begin
        running <= 1;
    end endtask
    always @(posedge clk) if(rst) reset(); else begin
        running <= do_microops;
    end 
endmodule