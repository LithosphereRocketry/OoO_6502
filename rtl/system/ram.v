`timescale 1ns/1ps

/*
Parametrized, synchronous single-port RAM
*/

module ram #(
        parameter ADDR_WIDTH = 16,
        parameter DATA_WIDTH = 8
    ) (
        input clk,
        input we1,
        input we2,
        input [ADDR_WIDTH-1:0] addr1,
        input [ADDR_WIDTH-1:0] addr2,
        input [DATA_WIDTH-1:0] data_in1,
        input [DATA_WIDTH-1:0] data_in2,
        output reg [DATA_WIDTH-1:0] data_out1,
        output reg [DATA_WIDTH-1:0] data_out2
    );

    reg [DATA_WIDTH-1:0] ram1 [0:(1<<ADDR_WIDTH)-1];
    reg [DATA_WIDTH-1:0] ram2 [0:(1<<ADDR_WIDTH)-1];

    always @(posedge clk) begin
        data_out1 <= ram1[addr1];
        data_out2 <= ram2[addr2];
        if(we1) ram1[addr1] <= data_in1;
        if(we2) ram2[addr2] <= data_in2;
    end 
endmodule