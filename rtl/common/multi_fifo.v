/*
FIFO allowing multiple inputs on one cycle
LSB end pushed first
*/

module multi_fifo #(
        parameter DATA_WIDTH = 32,
        parameter PUSH_WIDTH = 4,
        parameter ELEMENTS = 15
    ) (
        input clk,
        input rst,

        input [DATA_WIDTH*PUSH_WIDTH-1:0] din,
        input [$clog2(PUSH_WIDTH):0] din_valid_ct,
        output [$clog2(PUSH_WIDTH):0] din_ready_ct,

        output [DATA_WIDTH-1:0] dout,
        output dout_valid,
        input dout_ready
    );

    // slightly easier to have one slot always free - wastes one word of
    // memory, but simplifies logic for distinguishing full from empty
    localparam SLOTS = ELEMENTS+1;
    localparam ADDR_WIDTH = $clog2(SLOTS);

    reg [ADDR_WIDTH-1:0] read_ptr, write_ptr;

    task reset; begin
        read_ptr <= 0;
        write_ptr <= 0;
    end endtask

    reg [DATA_WIDTH-1:0] buffer [0:SLOTS-1];

    wire empty = (read_ptr == write_ptr);

    wire [ADDR_WIDTH-1:0] available = (read_ptr > write_ptr) ? (read_ptr - write_ptr - 1)
            : ELEMENTS - write_ptr + read_ptr;
    
    assign din_ready_ct = (available >= PUSH_WIDTH) ? PUSH_WIDTH : available;

    wire [$clog2(PUSH_WIDTH):0] num_pushes =
            din_valid_ct > din_ready_ct ? din_ready_ct : din_valid_ct;
    
    // Allow bypass when FIFO is empty
    assign dout = empty ? din[DATA_WIDTH-1:0] : buffer[read_ptr];
    assign dout_valid = empty ? (din_valid_ct > 0) : 1;

    initial reset();

    integer i;
    reg [ADDR_WIDTH-1:0] write_ptr_temp;
    always @(posedge clk) if(rst) reset(); else begin
        // make sure the loop depends on a constant so it's synthesizable
        // (it's still gonna be ugly)
        // (this whole thing is Bad Verilog, the priority is making it work)
        write_ptr_temp = write_ptr;
        for(i = 0; i < PUSH_WIDTH; i = i + 1) if(i < num_pushes) begin
            buffer[write_ptr_temp] <= din[i*DATA_WIDTH +: DATA_WIDTH];
            write_ptr_temp = (write_ptr_temp == SLOTS-1) ? 0 : write_ptr_temp + 1;
        end
        write_ptr <= write_ptr_temp;

        if(dout_ready & dout_valid) begin
            read_ptr <= (read_ptr == ELEMENTS) ? 0 : read_ptr + 1;
        end
    end

endmodule