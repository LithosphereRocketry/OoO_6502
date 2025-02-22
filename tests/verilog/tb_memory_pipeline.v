`timescale 1ns/1ps

module tb_memory_pipeline();

//     reg clk = 1;
//     reg [4:0] opcode;
//     reg [15:0] base_val;
//     reg [7:0] offset;
//     reg [4:0] dest_reg;
//     reg [7:0] data;
//     reg [3:0] imm;
//     reg [7:0] dest_arch_regs;
//     reg input_valid;

//     wire input_ready;
//     wire [15:0] mem_addr;
//     wire [4:0] dest_reg_out;
//     wire [7:0] data_out;
//     wire [7:0] dest_arch_regs_out;
//     wire store_out;
//     wire output_valid;
//     reg output_ready;

    
//     memory_pipeline dut (
//         .clk(clk),
//         .opcode(opcode),
//         .base_val(base_val),
//         .offset(offset),
//         .dest_reg(dest_reg),
//         .data(data),
//         .imm(imm),
//         .dest_arch_regs(dest_arch_regs),
//         .input_valid(input_valid),
//         .input_ready(input_ready),
//         .mem_addr(mem_addr),
//         .dest_reg_out(dest_reg_out),
//         .data_out(data_out),
//         .dest_arch_regs_out(dest_arch_regs_out),
//         .store_out(store_out),
//         .output_valid(output_valid),
//         .output_ready(output_ready)
//     );

//     task step; begin
//         clk = 0;
//         #1;
//         clk = 1;
//         #1;
//     end endtask

//     task assert_8;
//         input [7:0] data;
//         input [7:0] expected;
//         begin
//             if(data !== expected) begin
//                 $display("Error in ram: expected %h, got %h", expected, data);
//                 $fatal;
//             end
//         end
//     endtask

// integer i; 
//     initial begin
//         $dumpfile(`WAVEPATH);
//         $dumpvars;
        
//         // ld
//         opcode = 4'b1100;
//         base_val = 16'h0004;
//         offset = 8'h02;
//         dest_reg = 5'b00010;
//         data = 8'h0a;
//         imm = 4'b0000;
//         dest_arch_regs = 8'b11001100;
//         input_valid = 1;
//         output_ready = 1;

//         step();
//         assert_8(input_ready, 1'b1); // 1
//         assert_8(mem_addr, 16'h0006); // base_val + offset
//         assert_8(dest_reg_out, 5'b00010); // same as dest_reg
//         assert_8(data_out, 8'h0a); // same as data
//         assert_8(dest_arch_regs_out, 8'b11001100); // same as dest_arch_regs
//         assert_8(store_out, 1'b0); // opcode[0]
//         assert_8(output_valid, 1'b1); // 1

//         // st
//         opcode = 4'b1101;
//         base_val = 16'h0008;
//         offset = 8'h04;
//         dest_reg = 5'b00100;
//         data = 8'h0c;
//         imm = 4'b0000;
//         dest_arch_regs = 8'b00110011;
//         input_valid = 1;
//         output_ready = 1;

//         step();
//         assert_8(input_ready, 1'b1); // 1
//         assert_8(mem_addr, 16'h000c); // base_val + offset
//         assert_8(dest_reg_out, 5'b00100); // same as dest_reg
//         assert_8(data_out, 8'h0c); // same as data
//         assert_8(dest_arch_regs_out, 8'b00110011); // same as dest_arch_regs
//         assert_8(store_out, 1'b1); // opcode[0]
//         assert_8(output_valid, 1'b1); // 1

//         $finish;
//     end

endmodule
