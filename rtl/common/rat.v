module rat #(
        parameter NUM_LRS = 10,
        parameter ADDR_WIDTH = 5
    ) (
        input clk,
        input rst,
        input [NUM_LRS*ADDR_WIDTH-1:0] assignments_in,
        input [NUM_LRS-1:0] done_flags_in,

        output reg [NUM_LRS*ADDR_WIDTH-1:0] assignments,
        output reg [NUM_LRS-1:0] done_flags
    );

    integer i;
    task reset; begin
        done_flags <= (1 << NUM_LRS) - 1;
    end
    endtask

    initial reset();

    always @(posedge clk) if(rst) reset(); else begin
        assignments <= assignments_in;
        done_flags <= done_flags_in;
    end

endmodule