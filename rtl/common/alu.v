/*
Expects the "register address" of bit set/clear operations to be passed as the
*value* of operand b - to be handled in stage logic
*/

module alu(
        input [3:0] opcode,

        input [7:0] a,
        input [7:0] b,  
        input [7:0] f_in,

        output [7:0] q,
        output [7:0] f_out
    );

    wire [7:0] q_adder;
    wire [7:0] f_adder;
    adder _adder(
        .a(a),
        .b(b),
        .f_in(f_in),
        
        .mask_overflow(opcode[2]),

        .q(q_adder),
        .f_out(f_adder)
    );

    wire bitmask = (8'b1 << (b & 8'h7)) ^ {8{b[3]}};
    wire b_bitwise = opcode == 4'b1011 ? bitmask : b;

    wire [7:0] q_bitwise;
    wire [7:0] f_bitwise = f_in;
    bitwise _bitwise(
        .a(a),
        .b(b_bitwise),
        .op(opcode[1:0]),
        .q(q_bitwise)
    );

    wire [7:0] q_shifter;
    wire [7:0] f_shifter;
    shifter _shifter(
        .a(a),
        .f_in(f_in),
        .right(opcode[0]),
        .rotate(opcode[1]),
        .q(q_shifter),
        .f_out(f_shifter)
    );

    wire [7:0] f_module = (opcode == 4'h0 | opcode == 4'h1 | opcode == 4'h2) ? f_adder
                        : (opcode == 4'h3 | opcode == 4'h4 | opcode == 4'h5 | opcode == 4'hB) ? f_shifter
                        : f_bitwise;
    assign q = (opcode == 4'h0 | opcode == 4'h1 | opcode == 4'h2) ? q_adder
             : (opcode == 4'h3 | opcode == 4'h4 | opcode == 4'h5 | opcode == 4'hB) ? q_shifter
             : q_bitwise;
    
    wire [7:0] f_common = f_module & ~((1 << FLAG_NEGATIVE) | (1 << FLAG_ZERO))
                        | (q[7] << FLAG_NEGATIVE) | ((q == 8'h00) << FLAG_ZERO);
    
    // Weird edge case for BIT macroop
    wire [7:0] f_bittest = {b[7:6], f_common[5:0]};
    assign f_out = (opcode == 4'hA) ? f_bittest : f_common;
endmodule