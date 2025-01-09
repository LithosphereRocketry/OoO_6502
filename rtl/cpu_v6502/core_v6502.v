`timescale 1ns/1ps

module core(
        input clk,
        input rst,
        output [15:0] addr,   // address bus
        input [7:0] data_in,         // data in, read bus
        output [7:0] data_out,
        output we
        // input IRQ;              // interrupt request
        // input NMI;              // non-maskable interrupt request
        // input RDY;              // Ready signal. Pauses CPU when RDY=0 
    );

    cpu cpu(
        .clk(clk),
        .reset(~rst),
        .AB(addr),
        .DI(data_in),
        .DO(data_out),
        .WE(we),
        .IRQ(1'b1),
        .NMI(1'b1),
        .RDY(1'b1) // until we implement these features, just ignore them
    );

endmodule