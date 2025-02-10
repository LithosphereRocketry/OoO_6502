module issue_buff_seq #(
        parameter DATA_WIDTH = 47,
        parameter PUSH_WIDTH = 4,
        parameter ELEMENTS = 4
    ) (
        input clk,
        input rst,
        input [DATA_WIDTH*PUSH_WIDTH-1:0] din,
        input [$clog2(PUSH_WIDTH):0] din_valid_ct,
        output [$clog2(PUSH_WIDTH):0] din_ready_ct,

        output [DATA_WIDTH-1:0] dout,
        output dout_valid,
        input dout_ready,

        input [9:0] done_flags
    );

