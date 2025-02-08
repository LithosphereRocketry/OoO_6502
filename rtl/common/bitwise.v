/*

Bitwise unit

op 00: OR
op 01: XOR
op 1x: AND
*/

module bitwise(
        input [7:0] a,
        input [7:0] b,
        input [1:0] op,

        output [7:0] q
    );

    assign q = op[1] ? (a & b) : (op[0] ? (a ^ b) : (a | b));
endmodule