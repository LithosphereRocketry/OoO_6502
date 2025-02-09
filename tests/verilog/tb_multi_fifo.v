`timescale 1ns/1ps

module tb_multi_fifo();
    reg clk = 0;
    reg rst;
    reg [15:0] din;
    reg [2:0] din_valid_ct;
    wire [2:0] din_ready_ct;
    wire [3:0] dout;
    wire dout_valid;
    reg dout_ready;

    task step; begin
        clk = 0;
        #1;
        clk = 1;
        #1;
    end endtask

    task assert;
        input [31:0] data;
        input [31:0] expected;
        begin
            if(data !== expected) begin
                $display("Error: expected %h, got %h", expected, data);
                #2;
                $fatal;
            end
        end
    endtask


    multi_fifo #(
        .DATA_WIDTH(4),
        .PUSH_WIDTH(4),
        .ELEMENTS(9)
    ) dut (
        .clk(clk),
        .rst(rst),

        .din(din),
        .din_valid_ct(din_valid_ct),
        .din_ready_ct(din_ready_ct),

        .dout(dout),
        .dout_valid(dout_valid),
        .dout_ready(dout_ready)
    );

    integer i;
    initial begin
        $dumpfile(`WAVEPATH);
        $dumpvars;

        rst = 1;
        step();
        rst = 0;

        // Should be transparent when empty
        din = 'h4321;
        din_valid_ct = 1;
        dout_ready = 1;
        #1;
        assert(dout, 1);
        din = 'h8765;
        #1;
        assert(dout, 5);
        
        // Should remain transparent with single-element push/pops
        din = 'h3;
        step();
        din = 'h5;
        step();
        din = 'h4;
        step();
        din = 'h7;
        step();
        din = 'h9;
        #1;
        assert(dout, 'h9);

        // Push things of varying sizes until it's full
        dout_ready = 0;
        assert(din_ready_ct, 4);
        din = 'h321;
        din_valid_ct = 3;
        step();
        assert(din_ready_ct, 4);
        din = 'h7654;
        din_valid_ct = 4;
        step();
        assert(din_ready_ct, 2);
        din = 'hBA98;
        step();
        assert(din_ready_ct, 0);

        din_valid_ct = 0;
        dout_ready = 1;
        for(i = 1; i < 10; i++) begin
            assert(dout_valid, 1);
            assert(dout, i);
            step();
        end
        assert(dout_valid, 0);

        $finish;
    end

endmodule