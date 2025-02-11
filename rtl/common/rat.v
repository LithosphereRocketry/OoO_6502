module rat #(
        parameter NUM_LRS = 10,
        parameter ADDR_WIDTH = 5
    ) (
        input clk,
        input rst,
        input [NUM_LRS*ADDR_WIDTH-1:0] assignments_in,
        input [NUM_LRS-1:0] done_flags_in,
        input assignments_valid,
        input done_flags_ready,

        output [NUM_LRS*ADDR_WIDTH-1:0] assignments,
        output [NUM_LRS-1:0] done_flags
    );

    integer i;
    task reset; begin
        done_flags <= (1 << NUM_LRS) - 1;
    end
    endtask

    initial reset();

    always @(posedge clk) if(rst) reset(); else begin
        if(assignments_valid) assignments <= assignments_in;
        if(done_flags_ready) done_flags <= done_flags_in;
    end

endmodule