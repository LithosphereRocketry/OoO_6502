module tb_adder();
    reg [7:0] a;
    reg [7:0] b;
    reg [7:0] f_in;
    reg mask_overflow;

    wire [7:0] q;
    wire [7:0] f_out;

    adder dut(
        .a(a),
        .b(b),
        .f_in(f_in),
        .mask_overflow(mask_overflow),

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

        // test a basic add
        a = 12;
        b = 34;
        f_in = 0;
        mask_overflow = 0;
        #1;
        assert_8(q, 46);
        assert_8(f_out, 0);

        // test carry-in and unused-flag propagation
        f_in = 8'b01011011;
        #1;
        assert_8(q, 47);
        assert_8(f_out, 8'b00011010);

        // make sure we get overflow back when the mask bit is enabled
        mask_overflow = 1;
        #1;
        assert_8(f_out, 8'b01011010);

        $finish;
    end
endmodule