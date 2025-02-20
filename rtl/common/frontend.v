module frontend #(
    parameter FETCH_WIDTH = 4
) (
        input clk,
        input rst,

        input wakeup,
        input [7:0] instr,
        input instr_valid,
        output instr_ready,

        input [29:0] cmplt_free_regs,
        input [23:0] cmplt_dest_regs,
        input [19:0] ROB_entries,

        output [2*`PR_ADDR_W*FETCH_WIDTH-1:0] decoded_old_aliases,
        output old_aliases_valid
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
        .cmplt_dest_regs(cmplt_dest_regs),
        .ROB_entries(ROB_entries),

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
            assign op_is_term[g] = decoded_instrs[g*47 + 44 +: 3] == 3'b111;
    
    wire issuing_term = 
            |(op_is_term & decoded_instrs_ready & decoded_instrs_valid);
    reg running;
    assign do_microops = running ? ~issuing_term : wakeup;

    type_sort #(FETCH_WIDTH) sorter(
        .instr_in(decoded_instrs),
        .instr_valid(decoded_instrs_valid),
        .instr_used(decoded_instrs_ready),

        .instr_alu_ready(1'b1),
        .instr_mem_ready(1'b1),
        .instr_term_ready(1'b1)
    );

    task reset; begin
        running <= 1;
    end endtask
    always @(posedge clk) if(rst) reset(); else begin
        running <= do_microops;
    end 
endmodule