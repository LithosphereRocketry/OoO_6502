/*

*/

`include "constants.vh"

module decoder_cell(
        input [23:0] logical_instr,
        input logical_instr_valid,
        input logical_instr_ready,  

        input [`PHYS_REGS-3:0] free_pool,
        input [10*`PR_ADDR_W-1] rat_aliases,
        input [9:0] rat_done,

        output [`PHYS_REGS-3:0] free_pool_after,
        output [10*`PR_ADDR_W-1] new_rat_aliases,
        output [9:0] new_rat_done,

        output [`RENAMED_OP_SZ-1:0] decoded_instr,
        output decoded_instr_valid
        input decoded_instr_ready
    );

    // TODO

endmodule

module decoder #(
        parameter PIPELINES = 3
    ) (
        input clk,
        input rst,

        input [PIPELINES*24-1:0] logical_instrs,
        input [PIPELINES-1:0] logical_instrs_valid,
        output [PIPELINES-1:0] logical_instrs_ready,

        output [`RENAMED_OP_SZ*PIPELINES-1:0] decoded_instrs,
        output [PIPELINES-1:0] decoded_instrs_ready
    );

    wire [PIPELINES*4-1:0] opcode;
    genvar i;
    for(i = 0; i < PIPELINES; i = i + 1)
            assign opcode[4*i +: 4] = logical_instrs[24*i + 20 +: 4];

    reg [`PHYS_REGS-1:0] free_pool;

    wire [9:0] done_flags, done_flags_in;
    wire [10*`PR_ADDR_W-1:0] assignments, assignments_in;
    rat #(10, `PR_ADDR_W) _rat(
        .clk(clk),
        .rst(rst),
        .assignments_in(assignments_in),
        .done_flags_in(done_flags_in),
        .assignments(assignments),
        .done_flags(done_flags)
    );

    task reset; begin
        free_pool <= {`PHYS_REGS{1'b1}};
    end endtask

    initial reset();

    // TODO ASSIGN THINGS
    assign assignments_in = assignments;
    assign done_flags_in = done_flags;

    always @(posedge clk) if(rst) reset(); else begin

    end

endmodule