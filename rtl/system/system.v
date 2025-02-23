`timescale 1ns/1ps

module system(
        input clk,
        input rst,

        output [7:0] dport_out1,
        output [7:0] dport_out2,
        output dport_write1,
        output dport_write2,
        
        output done
    );
    wire we1;
    wire we2;
    wire [15:0] addr1;
    wire [15:0] addr2;
    wire [7:0] data_w1;
    wire [7:0] data_w2;
    wire [7:0] data_r1;
    wire [7:0] data_r2;

    assign dport_out1 = data_w1;
    assign dport_out2 = data_w2;
    assign dport_write1 = we1 & addr1 == 16'h4000;
    assign dport_write2 = we2 & addr2 == 16'h4000;
    assign done = (we1 & addr1 == 16'h4100) | (we2 & addr2 == 16'h4100);

    core core(
        .clk(clk),
        .rst(rst),
        .addr1(addr1),
        .addr2(addr2),
        .data_in1(data_r1),
        .data_in2(data_r2),
        .data_out1(data_w1),
        .data_out2(data_w2),
        .we1(we1),
        .we2(we2)
    );

    // The zero-page and stack are stored at 0x0000 and 0x0010, so the lowest
    // part of memory must be RAM. We choose this to be 16K arbitrarily.
    wire cs_ram1 = addr1[15:14] == 2'b00;
    wire cs_ram2 = addr2[15:14] == 2'b00;
    wire [7:0] data_ram1;
    wire [7:0] data_ram2;
    ram #(14, 8) m_ram(
        .clk(clk),
        .we1(we1 & cs_ram1),
        .we2(we2 & cs_ram2),
        .addr1(addr1[13:0]),
        .addr2(addr2[13:0]),
        .data_in1(data_w1),
        .data_in2(data_w2),
        .data_out1(data_ram1),
        .data_out2(data_ram2)
    );


    // The reset vector is stored at 0xFFFC, so the highest part of memory must
    // be ROM. We choose this to be 32K arbitrarily.
    wire cs_rom1 = addr1[15] == 1'b1;
    wire cs_rom2 = addr2[15] == 1'b1;
    wire [7:0] data_rom1;
    wire [7:0] data_rom2;
    rom #(`ROMPATH, 15, 8) m_rom(
        .clk(clk),
        .addr1(addr1[14:0]),
        .addr2(addr2[14:0]),
        .data_out1(data_rom1),
        .data_out2(data_rom2)
    );

    // For read operations, we have to register the chip selects to make sure
    // they appear on the same cycle as the data is valid
    reg cs_ram_reg1 = 0;
    always @(posedge clk) cs_ram_reg1 <= cs_ram1;
    reg cs_ram_reg2 = 0;
    always @(posedge clk) cs_ram_reg2 <= cs_ram2;
    reg cs_rom_reg1 = 0;
    always @(posedge clk) cs_rom_reg1 <= cs_rom1;
    reg cs_rom_reg2 = 0;
    always @(posedge clk) cs_rom_reg2 <= cs_rom2;
    
    assign data_r1 = {8{cs_ram_reg1}} & data_ram1
                  | {8{cs_rom_reg1}} & data_rom1;
    assign data_r2 = {8{cs_ram_reg2}} & data_ram2
                  | {8{cs_rom_reg2}} & data_rom2;
endmodule