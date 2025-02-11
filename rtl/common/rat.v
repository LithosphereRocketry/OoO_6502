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

        output [NUM_LRS*ADDR_WIDTH-1:0] assignments_out,
        output [NUM_LRS-1:0] done_flags_out
    );

    reg [NUM_LRS*ADDR_WIDTH-1:0] assignments;
    reg [NUM_LRS-1:0] done_flags;

    integer i;
    task reset; begin
        done_flags <= (1 << NUM_LRS) - 1;
        for(i = 0; i < NUM_LRS; i = i + 1) begin
            NUM_LRS[ADDR_WIDTH*(i+1)-1 +:ADDR_WIDTH] = i + 2;
        end
    end
    endtask

endmodule