`include "constants.vh"

/*
8-bit adder with carry properties compatible with 6502 semantics.

No BCD support yet.

Handles C and V flags; expects Z and N flags to be set by the rest of the ALU.
*/
module adder (
        input [7:0] a,
        input [7:0] b,
        input [7:0] f_in,

        input mask_overflow, // for correct CMP flag behavior

        output [7:0] q,
        output [7:0] f_out
    );
    localparam FLAG_MASK = (1 << `FLAG_CARRY) | (1 << `FLAG_OVERFLOW);

    wire cin = f_in[`FLAG_CARRY];

    wire [8:0] result = a + b + cin;

    wire cout = result[8];
    wire overflow = mask_overflow ? f_in[`FLAG_OVERFLOW] : (a[7] ^ result[7]) & (b[7] ^ result[7]);

    assign q = result[7:0];
    assign f_out = (f_in & ~FLAG_MASK) | (cout << `FLAG_CARRY) | (overflow << `FLAG_OVERFLOW);
endmodule