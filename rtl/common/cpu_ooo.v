module cpu_ooo(
        input clk,
        input rst,

        output [15:0] addr_i,
        input [7:0] din_i,

        output [15:0] addr_d,
        output [7:0] dout_d,
        output wr_d,
        input [7:0] din_d
    );

    wire instr_valid = 0;

    frontend _frontend(
        .clk(clk),
        .rst(rst),
        .wakeup(1'b0),
        .instr(din_i),
        .instr_valid(instr_valid)

    );

endmodule