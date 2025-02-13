module terminate_pipeline(
    input [3:0] opcode,
    input [15:0] reg_base_val,
    input [3:0] flag_index,
    input [7:0] flag_vals,
    input [7:0] offset,
    input [3:0] immediate,
    output [15:0] result_addr,
    output result_valid
);

wire [15:0] add = ({16{(opcode == 4'b1111)}} & {12'b0, immediate}) | ({16{(opcode == 4'b1110)}} & {8'b0, offset});
assign result_addr = reg_base_val + add;

assign result_valid = (opcode == 4'b1111) | ((opcode == 4'b1110) & (flag_vals[flag_index] == immediate[3]));

endmodule