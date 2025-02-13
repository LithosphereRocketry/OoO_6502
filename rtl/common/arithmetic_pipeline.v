module arithmetic_pipeline(
        input clk,
        input [3:0] opcode,
        input [4:0] ROB_entry,
        input [4:0] dest_reg,
        input [4:0] flag_reg,
        input [7:0] op_a_val,
        input [7:0] op_b_val,
        input [7:0] flags_val,

        input instr_valid,

        output [4:0] ROB_entry_out,
        output [4:0] dest_reg_out,
        output [4:0] flag_reg_out,
        output [7:0] result_val,
        output [7:0] result_flags
    );

    wire [7:0] alu_result;
    wire [7:0] alu_flags;

    alu _alu(
        .opcode(opcode),

        .a(op_a_val),
        .b(op_b_val),  
        .f_in(flags_val),

        .q(alu_result),
        .f_out(alu_flags)
    );

    always @(posedge clk) begin
        if(instr_valid) begin
            ROB_entry_out <= ROB_entry;
            dest_reg_out <= dest_reg;
            flag_reg_out <= flag_reg;
            result_val <= alu_result;
            result_flags <= alu_flags;
        end
    end

endmodule