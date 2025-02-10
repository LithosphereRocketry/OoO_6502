module issue_entry_capped #(
        parameter INST_WIDTH = 47
    )
    (
        input clk,
        input rst,
        input [9:0] done_flags,
        input [INST_WIDTH - 1: 0] instr,
        input input_valid,
        input output_ready,

        output [INST_WIDTH - 1: 0] instr_out,
        output input_ready,
        output output_valid
    );

    wire entry_ready;
    wire entry_valid;

    issue_entry _entry(
        .clk(clk),
        .rst(rst),
        .done_flags(done_flags),
        .instr(instr),
        .input_valid(input_valid),
        .output_ready(entry_ready),

        .instr_out(instr_out),
        .input_ready(input_ready),
        .output_valid(entry_valid)
    );

    issue_cap _cap(
        .entry_valid(entry_valid),
        .instr(instr_out),
        .next_ready(output_ready),

        .entry_ready(entry_ready),
        .result_valid(output_valid)
    );
endmodule