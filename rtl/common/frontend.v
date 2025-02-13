module frontend(
        input clk,
        input rst,

        input wakeup,
        input [7:0] instr,
        input instr_valid,
        output instr_ready
    );

    localparam FETCH_WIDTH = 4;

    wire microops_ready;
    wire [FETCH_WIDTH*24-1:0] microops;
    
    uop_fetch #(FETCH_WIDTH) fetch (
        .clk(clk),
        .rst(rst),
        .fetch(instr_valid),
        .macroop_in(instr),
        .microops_ready(microops_ready),
        .microops(microops)
    );

    wire [23:0] sort_instr_alu, sort_instr_mem, sort_instr_term;
    wire [FETCH_WIDTH-1:0] sort_instr_used;
    wire sort_alu_valid, sort_mem_valid, sort_term_valid;
    wire sort_alu_ready = 1, sort_mem_ready = 1, sort_term_ready = 1;
    wire sort_has_terminate;

    // TODO: WRONG: Sort has to happen after decoding
    type_sort #(FETCH_WIDTH) sort (
        .instr_in(microops),
        .instr_valid(instrs_waiting),
        .instr_used(sort_instr_used),
        .instr_alu(sort_instr_alu),
        .instr_alu_valid(sort_alu_valid),
        .instr_alu_ready(sort_alu_ready),
        .instr_mem(sort_instr_mem),
        .instr_mem_valid(sort_mem_valid),
        .instr_mem_ready(sort_mem_ready),
        .instr_term(sort_instr_term),
        .instr_term_valid(sort_term_valid),
        .instr_term_ready(sort_term_ready),
        .terminate(sort_has_terminate)
    );

    reg [FETCH_WIDTH-1:0] instrs_waiting;
    reg terminated;

    wire [FETCH_WIDTH-1:0] next_instrs_waiting = instrs_waiting & ~(sort_instr_used);

    assign microops_ready = ~terminated & ~sort_has_terminate & (next_instrs_waiting == 0);

    task reset; begin
        instrs_waiting <= {FETCH_WIDTH{1'b1}};
        terminated <= 0;
    end endtask
    initial reset();

    // TODO: not done (either instantiation or this module)
    decoder #(3) dec(
        .clk(clk),
        .rst(rst),

        .logical_instrs({sort_instr_term, sort_instr_mem, sort_instr_alu}),
        .logical_instrs_valid({sort_term_valid, sort_mem_valid, sort_alu_valid}),
        .logical_instrs_ready({sort_term_ready, sort_mem_ready, sort_alu_ready})
    );


    always @(posedge clk) if(rst) reset(); else begin
        // Uop fetch/distribute
        instrs_waiting <= microops_ready ? 4'b1111 : next_instrs_waiting;
        terminated <= (terminated | sort_has_terminate) & ~wakeup;
    end



endmodule