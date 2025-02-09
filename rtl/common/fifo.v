/*
Circular synchronous FIFO buffer
*/

module fifo #(
        parameter DATA_WIDTH = 32,
        parameter ELEMENTS = 15
    ) (
        input clk,
        input rst,
        
        input [DATA_WIDTH-1:0] din,
        input din_valid,
        output din_ready,

        output [DATA_WIDTH-1:0] dout,
        output dout_valid,
        input dout_ready
    );

    // slightly easier to have one slot always free - wastes one word of
    // memory, but simplifies logic for distinguishing full from empty
    localparam SLOTS = ELEMENTS+1;
    localparam ADDR_WIDTH = $clog2(SLOTS);

    reg [ADDR_WIDTH-1:0] read_ptr, write_ptr;

    wire [ADDR_WIDTH-1:0] read_next = (read_ptr == SLOTS-1) ? 0 : read_ptr+1;
    wire [ADDR_WIDTH-1:0] write_next = (write_ptr == SLOTS-1) ? 0 : write_ptr+1;

    // When read_ptr == write_ptr, the FIFO is empty
    // Otherwise, there is data to give
    assign dout_valid = read_ptr != write_ptr;
    // We are able to accept new data if doing so would not cause the FIFO to
    // wrap around the empty state
    // TODO: is it worth covering the case where we both read and write on the
    // same cycle when the FIFO is full? It's not an address conflict but adds a
    // bit of logic to detect
    assign din_ready = write_next != read_ptr;

    task reset; begin
        read_ptr <= 0;
        write_ptr <= 0;
    end endtask

    reg [DATA_WIDTH-1:0] buffer [0:ELEMENTS-1];

    assign dout = buffer[read_ptr];

    initial reset();

    always @(posedge clk) if(rst) reset(); else begin
        if(din_ready & din_valid) begin
            buffer[write_ptr] <= din;
            write_ptr <= write_next;
        end
        if(dout_ready & dout_valid) begin
            // Output is set combinatorially
            read_ptr <= read_next;
        end
    end


endmodule