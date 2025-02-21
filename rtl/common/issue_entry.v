module issue_entry #(
        parameter INST_WIDTH = 47
    )
    (
        input clk,
        input rst,
        input [29:0] done_flags,
        input [INST_WIDTH - 1: 0] instr,
        input input_valid,
        input output_ready,

        output [INST_WIDTH - 1: 0] instr_out,
        output input_ready,
        output output_valid
    );

    reg empty;
    reg [INST_WIDTH-1:0] data;
    reg [INST_WIDTH-1:0] flagged_data;
    reg [INST_WIDTH-1:0] flagged_data_tmp;

    task reset; begin
        empty <= 1;
        data <= {INST_WIDTH{1'bx}};
    end endtask

    assign input_ready = empty | output_ready;
    assign output_valid = !empty | input_valid;
    assign instr_out = empty ? instr : flagged_data;

    integer i;
    always @(*) begin
        flagged_data = data;
        for (i = 0; i < 4; i = i + 1) begin
            if(done_flags[data[13 + 5*i +: 4]-2]) flagged_data = flagged_data | (1 << (9+i));
        end
    end

    initial reset();

    always @(posedge clk) if(rst) reset(); else begin
        data <= ((input_valid & input_ready) ? instr : flagged_data);
        if(empty) begin
            empty <= !(input_valid & input_ready & output_ready);
        end
        else begin
            empty <= output_ready & !(input_ready & input_valid);
        end
    end

endmodule