module issue_cap #(
        parameter INST_WIDTH = 47
    )
    (
        input entry_valid,
        input [INST_WIDTH - 1: 0] instr,
        input next_ready,

        output entry_ready,
        output result_valid
    );

    wire ops_done;
    assign ops_done = instr[9] & instr[10] & instr[11] & instr[12];
    assign entry_ready = ops_done & next_ready;
    assign result_valid = ops_done & entry_valid;
    
endmodule