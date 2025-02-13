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
        input [ADDR_WIDTH-1:0] addr1,
        input [ADDR_WIDTH-1:0] addr2,
        output reg [DATA_WIDTH-1:0] data_out1,
        output reg [DATA_WIDTH-1:0] data_out2
    );

    reg [DATA_WIDTH-1:0] rom1 [0:(1<<ADDR_WIDTH)-1];
    reg [DATA_WIDTH-1:0] rom2 [0:(1<<ADDR_WIDTH)-1];
    initial $readmemh(FILE_PATH, rom1);
    initial $readmemh(FILE_PATH, rom2);

    always @(posedge clk) data_out1 <= rom1[addr1];
    always @(posedge clk) data_out2 <= rom2[addr2];
endmodule