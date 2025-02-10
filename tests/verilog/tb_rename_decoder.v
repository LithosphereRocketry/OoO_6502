`timescale 1ns/1ps;

module tb_rename_decoder();
    reg [23:0] microop;
    reg [9:0] rat_done = 10'b0101010101;
    reg [49:0] rat_aliases = {
        5'h19,
        5'h18,
        5'h17,
        5'h16,
        5'h15,
        5'h14,
        5'h13,
        5'h12,
        5'h11,
        5'h10
    };
    wire [19:0] src_regs;
    wire [3:0] src_ready;
    wire [3:0] immediate;

    rename_decoder dut(
        .microop(microop),

        .rat_done(rat_done),
        .rat_aliases(rat_aliases),

        .src_regs(src_regs),
        .src_ready(src_ready),
        .immediate(immediate)
    );

    task assert;
        input [31:0] data;
        input [31:0] expected;
        begin
            if(data !== expected) begin
                $display("Error: expected %b, got %b", expected, data);
                #2;
                $fatal;
            end
        end
    endtask

    initial begin
        $dumpfile(`WAVEPATH);
        $dumpvars;

        microop = {24'h034096};
        #1;
        assert(src_regs, {5'h0, 5'h0, 5'h17, 5'h14});
        assert(src_ready, 4'b1101);

        microop = {24'hB0307F};
        #1;
        assert(src_regs, {5'h0, 5'h0, 5'h15, 5'h0});
        assert(src_ready, 4'b1101);
        assert(immediate, 5'hF);

        microop = {24'hC86943};
        #1;
        assert(src_regs, {5'h0, 5'h17, 5'h12, 5'h11});
        assert(src_ready, 4'b1010);
        assert(immediate, 4'h8);

        microop = {24'hD88723};
        #1;
        assert(src_regs, {5'h16, 5'h15, 5'h10, 5'h11});
        assert(src_ready, 4'b1010);
        assert(immediate, 4'h8);

        microop = {24'hE67356};
        #1;
        assert(src_regs, {5'h15, 5'h11, 5'h13, 5'h14});
        assert(src_ready, 4'b0001);
        assert(immediate, 4'h6);

        microop = {24'hF98009};
        #1;
        assert(src_regs, {5'h16, 5'h0, 5'h0, 5'h17});
        assert(src_ready, 4'b1110);
        assert(immediate, 4'h9);

        $finish;
    end

    
endmodule