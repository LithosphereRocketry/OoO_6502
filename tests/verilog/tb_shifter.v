`timescale 1ns/1ps

module tb_shifter();
    reg [7:0] a;
    reg [7:0] f_in;
    reg rotate;
    reg right;

    wire [7:0] q;
    wire [7:0] f_out;

    shifter dut(
        .a(a),
        .f_in(f_in),
        .rotate(rotate),
        .right(right),
        .q(q),
        .f_out(f_out)
    );

    task assert_8;
        input [7:0] data;
        input [7:0] expected;
        begin
            if(data !== expected) begin
                $display("Error in adder: expected %h, got %h", expected, data);
                $fatal;
            end
        end
    endtask

    initial begin
        $dumpfile(`WAVEPATH);
        $dumpvars;

        // TODO: write more thorough tests
        a = 12;
        f_in = 0;
        right = 0;
        rotate = 0;
        #1;
        assert_8(q, 24);
        assert_8(f_out, 0);

        // test carry-in and unused-flag propagation
        f_in = 8'b01011011;
        #1;
        assert_8(q, 24);
        assert_8(f_out, 8'b01011010);

        rotate = 1;
        #1;
        assert_8(q, 25);
        assert_8(f_out, 8'b01011010);

        a = 179;
        rotate = 0;
        #1;
        assert_8(q, 102);
        assert_8(f_out, 8'b01011011);


        a = 12;
        f_in = 0;
        right = 1;
        rotate = 0;
        #1;
        assert_8(q, 6);
        assert_8(f_out, 0);

        a = 13;
        #1;
        assert_8(q, 6);
        assert_8(f_out, 1);

        f_in = 8'b01011011;
        #1;
        assert_8(q, 6);
        assert_8(f_out, 8'b01011011);

        $finish;
    end

endmodule
