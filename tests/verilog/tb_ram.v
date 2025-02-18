`timescale 1ns/1ps

module tb_ram();

    reg clk = 1;
    reg we1 = 0;
    reg we2 = 0;
    reg [14:0] addr1;
    reg [14:0] addr2;
    reg [7:0] data_in1;
    reg [7:0] data_in2;
    wire [7:0] data_out1;
    wire [7:0] data_out2;

    wire [7:0] expected1 = (addr1 >> 8) ^ addr1;
    wire [7:0] expected2 = (addr2 >> 8) ^ addr2;

    ram #(15, 8) dut (
        .clk(clk),
        .we1(we1),
        .we2(we2),
        .addr1(addr1),
        .addr2(addr2),
        .data_in1(data_in1),
        .data_in2(data_in2),
        .data_out1(data_out1),
        .data_out2(data_out2)
    );

    task step; begin
        clk = 0;
        #1;
        clk = 1;
        #1;
    end endtask

    task assert_8;
        input [7:0] data;
        input [7:0] expected;
        begin
            if(data !== expected) begin
                $display("Error in ram: expected %h, got %h", expected, data);
                $fatal;
            end
        end
    endtask

    task write;
        input [14:0] a;
        input [14:0] b;
        input [7:0] d;
        begin
            we1 = 1;
            addr1 = a;
            data_in1 = d;
            we2 = 1;
            addr2 = b;
            data_in2 = d;
            step();
        end
    endtask

    task read;
        input [14:0] a;
        input [14:0] b;
        begin
            we1 = 0;
            addr1 = a;
            data_in1 = 8'hxx;
            we2 = 0;
            addr2 = b;
            data_in2 = 8'hxx;
            step();
        end
    endtask

    integer i; 
    initial begin
        $dumpfile(`WAVEPATH);
        $dumpvars;
        
        write(15'h1234, 15'h3456, 8'h56);
        write(15'h5678, 15'h7891, 8'h9a);

        read(15'h1234, 15'h3456);
        assert_8(data_out1, 8'h56);
        assert_8(data_out2, 8'h56);
        read(15'h5678, 15'h7891);
        assert_8(data_out1, 8'h9a);
        assert_8(data_out2, 8'h9a);

        // The 6502 core expects reads to still work when writing on the next
        // cycle
        write(15'h5678, 15'h3456, 8'h03);
        assert_8(data_out1, 8'h9a);
        assert_8(data_out2, 8'h56);

        $finish;
    end

endmodule