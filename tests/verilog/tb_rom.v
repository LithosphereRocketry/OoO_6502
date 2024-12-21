`timescale 1ns/1ps

module tb_rom();

    reg clk = 1;
    reg [14:0] addr;
    wire [7:0] data;

    wire [7:0] expected = (addr >> 8) ^ addr;

    rom #("rom/hash.hex", 15, 8) dut (
        .clk(clk),
        .addr(addr),
        .data_out(data)
    );

    integer i; 
    initial begin
        $dumpfile(`WAVEPATH);
        $dumpvars;

        for(i = 0; i < 1<<15; i = i+1) begin
            addr = i;
            clk = 0;
            #1;
            clk = 1;
            #1;
            if(data != expected) begin
                $display("Error in rom: expected %h at address %h, got %h",
                        expected, addr, data);
                $fatal;
            end
        end
        $finish;
    end

endmodule