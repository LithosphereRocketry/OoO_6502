`timescale 1ns/1ps

module tb_ram();

    reg clk = 1;
    reg we = 0;
    reg [14:0] addr;
    reg [7:0] data_in;
    wire [7:0] data_out;

    wire [7:0] expected = (addr >> 8) ^ addr;

    ram #(15, 8) dut (
        .clk(clk),
        .we(we),
        .addr(addr),
        .data_in(data_in),
        .data_out(data_out)
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
        input [7:0] d;
        begin
            we = 1;
            addr = a;
            data_in = d;
            step();
        end
    endtask

    task read;
        input [14:0] a;
        begin
            we = 0;
            addr = a;
            data_in = 8'hxx;
            step();
        end
    endtask

    integer i; 
    initial begin
        $dumpfile(`WAVEPATH);
        $dumpvars;
        
        write(15'h1234, 8'h56);
        write(15'h5678, 8'h9a);

        read(15'h1234);
        assert_8(data_out, 8'h56);
        read(15'h5678);
        assert_8(data_out, 8'h9a);

        // The 6502 core expects reads to still work when writing on the next
        // cycle
        write(15'h5678, 8'h03);
        assert_8(data_out, 8'h9a);

        $finish;
    end

endmodule