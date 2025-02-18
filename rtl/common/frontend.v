module frontend #(
    localparam FETCH_WIDTH = 4
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

        output [10*FETCH_WIDTH-1:0] decoded_old_aliases
    );

    wire microops_ready;
    wire [FETCH_WIDTH*24-1:0] microops;
    
    uop_fetch #(FETCH_WIDTH) fetch (
        .clk(clk),
        .rst(rst),
        .fetch(wakeup & instr_valid),
        .macroop_in(instr),
        .microops_ready(microops_ready),
        .microops(microops)
    );

    wire [FETCH_WIDTH-1:0] decoded_instrs_ready, decoded_instrs_valid;

    decoder #(FETCH_WIDTH) _decoder(
        .clk(clk),
        .rst(rst),

        .cmplt_free_regs(cmplt_free_regs),
        .cmplt_dest_regs(cmplt_dest_regs),
        .ROB_entries(ROB_entries),

        .logical_instrs(microops),
        .logical_instrs_valid(),
        .logical_instrs_ready(),

        .decoded_instrs(),
        .decoded_arch_regs(),
        .decoded_old_aliases(decoded_old_aliases),
        .decoded_instrs_ready(decoded_instrs_ready),
        .decoded_instrs_valid(decoded_instrs_valid)
    );

    genvar g;
    wire [FETCH_WIDTH-1:0] op_is_term;
    for(g = 0; g < FETCH_WIDTH; g = g + 1)
            assign op_is_term[g] = microops[g*24 + 21 +: 3] == 3'b111;
    
    wire issuing_term = 
            |(op_is_term & decoded_instr_ready & decoded_instr_valid);
    reg running;

    assign microops_ready = running | wakeup;

    task reset(); begin
        running <= 1;
    end endtask
    always @(posedge clk) if(rst) reset(); else begin
        if(issuing_term & running) running <= 0;
        if(wakeup & ~running) running <= 1;
    end 
endmodule