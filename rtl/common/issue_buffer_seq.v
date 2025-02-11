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

    wire [ELEMENTS:0] valids;
    wire [ELEMENTS:0] readys;
    wire [ELEMENTS*DATA_WIDTH-1:0] instrs;

    issue_entry entries [ELEMENTS-1:0] (
        .clk(clk),
        .rst(rst),
        .done_flags(done_flags),
        .instr(instrs[ELEMENTS*DATA_WIDTH-1:DATA_WIDTH]),
        .input_valid(valids[ELEMENTS:1]),
        .output_ready(readys[ELEMENTS-1:0]),

        .instr_out(instrs[(ELEMENTS-1)*DATA_WIDTH-1:0]),
        .input_ready(readys[ELEMENTS:1]),
        .output_valid(valids[ELEMENTS-1:0])
    );

    assign dout = instrs[DATA_WIDTH-1:0];
    assign instrs[ELEMENTS*DATA_WIDTH-1+:DATA_WIDTH] = din;
    assign valids[ELEMENTS] = din_valid;
    assign din_ready = readys[ELEMENTS];

    issue_cap #(.INST_WIDTH(47)) _cap (
        .entry_valid(valids[0]),
        .instr(instrs[DATA_WIDTH-1:0]),
        .next_ready(dout_ready),

        .entry_ready(readys[0]),
        .result_valid(dout_valid)
    );

endmodule