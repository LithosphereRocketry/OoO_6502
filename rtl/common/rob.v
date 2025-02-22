/*
FIFO allowing multiple inputs on one cycle
LSB end pushed first
*/

module rob #(
        parameter DATA_WIDTH = 11,
        parameter PUSH_WIDTH = 4,
        parameter ELEMENTS = 15
    ) (
        input clk,
        input rst,

        input [(DATA_WIDTH-1)*PUSH_WIDTH-1:0] din,
        input [PUSH_WIDTH-1:0] din_valid,
        output [2:0] din_ready_ct,

        output reg [(DATA_WIDTH-1)*3-1:0] dout,
        output reg [$clog2(3):0] dout_valid_ct,
        input [$clog2(3):0] dout_ready_ct,

        output reg [($clog2(ELEMENTS+1)+1)*4-1:0] entry_nums,

        input [($clog2(ELEMENTS+1)+1)*3-1:0] completed,
        input [2:0] cmplt_valid
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
    
    wire [ADDR_WIDTH-1:0] occupied = ELEMENTS - available;
    
    assign din_ready_ct = (available >= PUSH_WIDTH) ? PUSH_WIDTH : available;

    integer i;
    always @(*) begin
        for(i = 0; i < 4; i = i + 1) begin
            if(write_ptr + i < SLOTS) entry_nums[ADDR_WIDTH*i +: ADDR_WIDTH] <= write_ptr + 1;
            else entry_nums[ADDR_WIDTH*i +: ADDR_WIDTH] <= write_ptr + 1 - SLOTS;
        end
    end

    initial reset();


    integer index;
    integer valid;
    reg [ADDR_WIDTH-1:0] write_ptr_temp, read_ptr_tmp;
    always @(posedge clk) if(rst) reset(); else begin
        // make sure the loop depends on a constant so it's synthesizable
        // (it's still gonna be ugly)
        // (this whole thing is Bad Verilog, the priority is making it work)
        write_ptr_temp = write_ptr;
        for(i = 0; i < PUSH_WIDTH; i++) if((i < din_ready_ct) & din_valid[i]) begin
            buffer[write_ptr_temp] <= {din[i*(DATA_WIDTH-1) +: DATA_WIDTH-1], 1'b0};
            write_ptr_temp = (write_ptr_temp == SLOTS-1) ? 0 : write_ptr_temp + 1;
        end
        write_ptr <= write_ptr_temp;

        for(i = 0; i < PUSH_WIDTH; i++) if(cmplt_valid[i]) begin
            buffer[completed[i*ADDR_WIDTH +: ADDR_WIDTH]][0] = 1;
        end

        // add all complete instructions (up to the push width) to the output
        valid = 1;
        read_ptr_tmp = read_ptr;
        for(i = 0; i < 3; i++) if((i < dout_ready_ct) & (i < occupied)) begin
            index = read_ptr + i;
            if(index > ELEMENTS) index = index - SLOTS;
            if(valid) if(buffer[index][0]) begin
                dout[DATA_WIDTH*i +: DATA_WIDTH-1] = buffer[index][DATA_WIDTH-1:1];
                dout_valid_ct = dout_valid_ct + 1;
                read_ptr_tmp = (read_ptr_tmp == SLOTS-1) ? 0 : read_ptr_tmp + 1;
            end else begin
                valid = 0;
                dout[DATA_WIDTH*i +: DATA_WIDTH-1] = 0;
            end
        end
        read_ptr = read_ptr_tmp;
    end

endmodule