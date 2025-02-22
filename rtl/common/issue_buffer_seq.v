module issue_buffer_seq #(
        parameter DATA_WIDTH = `RENAMED_OP_SZ,
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

        input [29:0] done_flags
    );

    wire [ELEMENTS-2:0] valids;
    wire [ELEMENTS-2:0] readys;
    wire [(ELEMENTS-1)*DATA_WIDTH-1:0] instrs;
    wire cap_ready, cap_valid;
    wire [DATA_WIDTH-1:0] instr_cap;

    issue_entry #(DATA_WIDTH) entries [ELEMENTS-1:0] (
        .clk(clk),
        .rst(rst),
        .done_flags(done_flags),
        .instr({din, instrs}),
        .input_valid({din_valid, valids}),
        .output_ready({readys, cap_ready}),

        .instr_out({instrs, dout}),
        .input_ready({din_ready, readys}),
        .output_valid({valids, cap_valid})
    );

    issue_cap #(.INST_WIDTH(DATA_WIDTH)) _cap (
        .entry_valid(cap_valid),
        .instr(dout),
        .next_ready(dout_ready),

        .entry_ready(cap_ready),
        .result_valid(dout_valid)
    );

endmodule