module issue_entry #(
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

    reg empty;
    reg [INST_WIDTH-1:0] data;
    reg [INST_WIDTH-1:0] flagged_data;
    reg [INST_WIDTH-1:0] flagged_data_tmp;

    task reset; begin
        empty <= 0;
        data <= {INST_WIDTH{1'bx}};
    end endtask

    assign input_ready = empty | output_ready;
    assign output_valid = !empty | input_valid;
    assign instr_out = empty? instr : flagged_data;

    integer i;
    always @(*) begin
        for (i = 0; i < 4; i = i + 1) begin
            if(done_flags & (1 << data[17+5*i:13+5*i])) flagged_data_tmp <= data | (1 << (9+i));
        end
        flagged_data <= flagged_data_tmp;
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