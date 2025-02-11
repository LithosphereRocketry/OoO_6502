module issue_buff_seq #(
        parameter DATA_WIDTH = 47,
        parameter ELEMENTS = 4
    ) (
        input clk,
        input rst,
        input [DATA_WIDTH-1:0] din,
        input din_valid,
        output din_ready,

        output [DATA_WIDTH-1:0] dout,
        output dout_valid,
        input dout_ready,

        input [9:0] done_flags
    );

endmodule