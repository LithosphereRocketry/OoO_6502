`timescale 1ns/1ps

/*
Parametrized, synchronous ROM
*/

module rom #(
        parameter FILE_PATH = "",
        parameter ADDR_WIDTH = 16,
        parameter DATA_WIDTH = 8
    ) (
        input clk,
        input [ADDR_WIDTH-1:0] addr,
        output reg [DATA_WIDTH-1:0] data_out
    );

    reg [DATA_WIDTH-1:0] rom [0:(1<<ADDR_WIDTH)-1];
    initial $readmemh(FILE_PATH, rom);

    always @(posedge clk) data_out <= rom[addr];
endmodule