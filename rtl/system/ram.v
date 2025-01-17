`timescale 1ns/1ps

/*
Parametrized, synchronous single-port RAM
*/

module ram #(
        parameter ADDR_WIDTH = 16,
        parameter DATA_WIDTH = 8
    ) (
        input clk,
        input we,
        input [ADDR_WIDTH-1:0] addr,
        input [DATA_WIDTH-1:0] data_in,
        output reg [DATA_WIDTH-1:0] data_out
    );

    reg [DATA_WIDTH-1:0] ram [0:(1<<ADDR_WIDTH)-1];

    always @(posedge clk) begin
        data_out <= ram[addr];
        if(we) ram[addr] <= data_in;
    end 
endmodule