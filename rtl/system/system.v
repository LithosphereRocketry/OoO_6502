`timescale 1ns/1ps

module system(
        input clk,

        output [7:0] dport_out,
        output dport_write,
        
        output done
    );
    wire we;
    wire [15:0] addr;
    wire [7:0] data_w;
    wire [7:0] data_r;

    // The zero-page and stack are stored at 0x0000 and 0x0010, so the lowest
    // part of memory must be RAM. We choose this to be 16K arbitrarily.
    wire cs_ram = addr[15:14] == 2'b00;
    wire [7:0] data_ram;
    ram #(14, 8) m_ram(
        .clk(clk),
        .we(we & cs_ram),
        .addr(addr[13:0]),
        .data_in(data_w),
        .data_out(data_ram)
    );


    // The reset vector is stored at 0xFFFC, so the highest part of memory must
    // be ROM. We choose this to be 32K arbitrarily.
    wire cs_rom = addr[15] == 1'b1;
    wire [7:0] data_rom;
    rom #(`ROMPATH, 15, 8) m_rom(
        .clk(clk),
        .addr(addr[14:0]),
        .data_out(data_rom)
    );

    assign data_r = {8{cs_ram}} & data_ram
                  | {8{cs_rom}} & data_rom;
endmodule