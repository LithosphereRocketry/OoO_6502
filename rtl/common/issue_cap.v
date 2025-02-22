module issue_cap #(
        parameter INST_WIDTH = `RENAMED_OP_SZ
    )
    (
        input entry_valid,
        input [INST_WIDTH - 1: 0] instr,
        input next_ready,

        output entry_ready,
        output result_valid
    );

    wire ops_done;
    assign ops_done = &instr[7:4];
    assign entry_ready = ops_done & next_ready;
    assign result_valid = ops_done & entry_valid;
    
endmodule