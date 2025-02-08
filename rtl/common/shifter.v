`include "constants.vh"

/*
8-bit shifter with carry properties compatible with 6502 semantics.

Handles C flag; expects Z and N flags to be set by the rest of the ALU.
*/
module shifter (
        input [7:0] a,
        input [7:0] f_in,

        input right,
        input rotate,

        output [7:0] q,
        output [7:0] f_out
    );
    localparam FLAG_MASK = (1 << `FLAG_CARRY);

    wire cin = rotate ? f_in[`FLAG_CARRY] : 1'b0;

    wire [8:0] result = right ? {cin, a} : {a, cin};
    wire cout = right ? result[0] : result[8];

    assign q = right ? result[8:1] : result[7:0];
    assign f_out = (f_in & ~FLAG_MASK) | (cout << `FLAG_CARRY);
endmodule