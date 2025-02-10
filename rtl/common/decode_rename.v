`include "constants.vh"

module decode_rename(
        input [7:0] rat_valid,
        input [8*8-1:0] rat_values,
        input [$clog2(`PHYS_REGS)*8-1:0] rat_aliases,

        input [23:0] instr,
        input [15:0] macro_pc,
        
        input [`PHYS_REGS-2:0] available_in,
        output [`PHYS_REGS-2:0] available_out,

        output [`RENAMED_OP_SZ-1:0] instr_renamed,
        output rename_success
    );

    // TODO: RAT

    wire [7:0] const_values [3:0];
    assign const_values[0] = 0;
    assign const_values[1] = 1;
    assign const_values[2] = (macro_pc + 1) & 8'hFF;
    assign const_values[3] = ((macro_pc + 1) >> 8) & 8'hFF;

    function [8:0] resolve_alias(input [3:0] areg); begin
        resolve_alias = 
                // if it's a (microop-time) constant, resolve it for free
                (areg < 4) ? {1'b0, const_values[areg]}
                // if the RAT/ARF has it, resolve it
                : rat_valid[areg-4] ? {1'b0, rat_values[(areg-4)*8 +: 8]}
                // otherwise, mark as unknown
                : {1'b1, {8-$clog2(`PHYS_REGS){1'b0}}, }

    end endfunction 

    wire any_first, any_second;
    wire [$clog2(`PHYS_REGS)-1:0] first_reg, second_reg;

    priority_enc enc_first(
        .in(available),
        .any(any_first),
        .out(first_reg)
    );
    wire [`PHYS_REGS-2:0] after_first = available & ~(any_first << first_reg);
    priority_enc enc_second(
        .in(available),
        .any(any_second),
        .out(second_reg)
    );
    wire [`PHYS_REGS-2:0] after_second = after_first & ~(any_first << first_reg);

    wire [3:0] opcode = instr[23:20];

    // as usual, blegh always @*
    always @* case(opcode)
        default: begin // Normal 3-in, 2-out ALU op
            rename_success = any_second; // success if we were able to find 2
            // physical registers free
            // Minor quibble here, we can maybe squeeze more perf by relaxing
            // this constraint when one or both physical registers are discards
            // but this is way too small to care
            available_out = 
        end
    endcase
endmodule