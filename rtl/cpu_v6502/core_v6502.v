`timescale 1ns/1ps

module core(
        input clk,
        input rst,
        output [15:0] addr1,   // address bus
        output [15:0] addr2,   // address bus
        input [7:0] data_in1,         // data in, read bus
        input [7:0] data_in2,         // data in, read bus
        output [7:0] data_out1,
        output [7:0] data_out2,
        output we1,
        output we2
        // input IRQ;              // interrupt request
        // input NMI;              // non-maskable interrupt request
        // input RDY;              // Ready signal. Pauses CPU when RDY=0 
    );

    assign we2 = 0;

    cpu cpu(
        .clk(clk),
        .reset(rst),
        .AB(addr1),
        .DI(data_in1),
        .DO(data_out1),
        .WE(we1),
        .IRQ(1'b0),
        .NMI(1'b0),
        .RDY(1'b1) // until we implement these features, just ignore them
    );

endmodule