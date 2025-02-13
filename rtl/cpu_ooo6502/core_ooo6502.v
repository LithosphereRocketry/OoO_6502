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

    cpu_ooo cpu(
        .clk(clk),
        .rst(rst),

        .addr_i(addr),
        .din_i(data_in)
        
        // TODO: second port
    );

endmodule