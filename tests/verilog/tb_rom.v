`timescale 1ns/1ps

module tb_rom();

    reg clk = 1;
    reg [14:0] addr1;
    reg [14:0] addr2;
    wire [7:0] data1;
    wire [7:0] data2;

    wire [7:0] expected1 = (addr1 >> 8) ^ addr1;
    wire [7:0] expected2 = (addr2 >> 8) ^ addr2;

    rom #("rom/hash.hex", 15, 8) dut (
        .clk(clk),
        .addr1(addr1),
        .addr2(addr2),
        .data_out1(data1),
        .data_out2(data2)
    );

    integer i; 
    initial begin
        $dumpfile(`WAVEPATH);
        $dumpvars;

        for(i = 0; i < 1<<15; i = i+1) begin
            addr1 = i;
            addr2 = i;
            clk = 0;
            #1;
            clk = 1;
            #1;
            if(data1 != expected1) begin
                $display("Error in rom: expected %h at address %h, got %h",
                        expected1, addr1, data1);
                $fatal;
            end
            if(data2 != expected2) begin
                $display("Error in rom: expected %h at address %h, got %h",
                    expected2, addr2, data2);
                $fatal;
            end
        end
        $finish;
    end

endmodule