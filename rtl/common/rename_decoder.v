/*
Translates source portion of microops into physical registers based on contents
of RAT
*/

`include "constants.vh"

module rename_decoder_cell(
        input [3:0] arch_reg,

        input [9:0] rat_done,
        input [`PR_ADDR_W*10 - 1:0] rat_aliases,

        output [`PR_ADDR_W-1:0] phys_reg,
        output ready
    );

    assign phys_reg = arch_reg == 4'h0 ? 5'h00
                    : arch_reg == 4'h1 ? 5'h01
                    : rat_aliases[(arch_reg-2)*`PR_ADDR_W +: `PR_ADDR_W];
    assign ready = (arch_reg == 4'h0 | arch_reg == 4'h1) ? 1'b1
                : ((rat_done & (1 << (arch_reg-2))) != 0) ;
    wire tmp, tmp1;
    assign tmp = (rat_done & (1 << (arch_reg-2))) != 0;
    assign tmp1 = rat_done[arch_reg - 2];

endmodule

module rename_decoder(
        input [23:0] microop,

        input [9:0] rat_done,
        input [`PR_ADDR_W*10 - 1:0] rat_aliases,

        output [`PR_ADDR_W*4-1:0] src_regs,
        output [3:0] src_ready,
        output [3:0] immediate
    );

    reg [15:0] src_arch; // combinational
    reg [3:0] imm; // combinational
    assign immediate = imm;

    rename_decoder_cell decoder_cells [3:0] (
        .arch_reg(src_arch),
        
        .rat_done(rat_done),
        .rat_aliases(rat_aliases),

        .phys_reg(src_regs),
        .ready(src_ready)
    );

    wire [3:0] opcode = microop[23:20];
    // blah blah always @* bad
    always @* case(opcode)
        4'b1011: begin // bit
            imm = microop[3:0];
            src_arch = {4'h0, microop[11:4], 4'h0};
        end
        4'b1100: begin // load
            imm = microop[19:16];
            src_arch = {4'h0, microop[11:0]};
        end
        4'b1101: begin // store
            imm = microop[19:16];
            src_arch = microop[15:0];
        end
        4'b1110: begin // cterm
            imm = microop[3:0];
            src_arch = {microop[15:4], microop[19:16]};
            // slightly backwards to ensure registers land in consistent locations
        end
        4'b1111: begin // term
            imm = microop[3:0];
            src_arch = {microop[15:12], 8'h00, microop[19:16]};
            // slightly backwards to ensure registers land in consistent locations
        end
        default: begin // Normal operation: 2 outputs, 3 inputs
            imm = 4'hx;
            src_arch = {4'h0, microop[11:0]};
        end
    endcase
endmodule