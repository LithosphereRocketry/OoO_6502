`timescale 1ns/1ps

module tb_terminate_pipeline();

    reg [3:0] opcode;
    reg [15:0] reg_base_val;
    reg [3:0] flag_index;
    reg [7:0] flag_vals;
    reg [7:0] offset;
    reg [3:0] immediate;
    wire [15:0] result_addr;
    wire result_valid;

    
    terminate_pipeline dut (
        .opcode(opcode),
        .reg_base_val(reg_base_val),
        .flag_index(flag_index),
        .flag_vals(flag_vals),
        .offset(offset),
        .immediate(immediate),
        .result_addr(result_addr),
        .result_valid(result_valid),
    )

    task step; begin
        clk = 0;
        #1;
        clk = 1;
        #1;
    end endtask

    task assert_8;
        input [7:0] data;
        input [7:0] expected;
        begin
            if(data !== expected) begin
                $display("Error in ram: expected %h, got %h", expected, data);
                $fatal;
            end
        end
    endtask

integer i; 
    initial begin
        $dumpfile(`WAVEPATH);
        $dumpvars;
        
        // unconditionally terminate
        opcode = 4'b1111; // do care
        reg_base_val = 16'h0008; // do care
        flag_vals = 8'h00; // don't care
        offset 8'h00; // don't care
        immediate = 4'b0001; // do care

        // terminate if bit of flags is true
        opcode = 4'b1110;
        reg_base_val = 16'h0008;
        flag_vals = 8'b00000001;
        offset = 8'h01;
        immediate = 4'b0001; // bit 1 of flag_vals

        // terminate if bit of flags is false
        opcode = 4'b1110;
        reg_base_val = 16'h0009;
        flag_vals = 8'b11110111;
        offset = 8'h02;
        immediate = 4'b1100; // bit 4 of flag_vals

        $finish;
    end

endmodule
