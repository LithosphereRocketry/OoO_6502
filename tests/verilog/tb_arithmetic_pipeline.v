`timescale 1ns/1ps

module tb_arithmetic_pipeline();

    reg clk = 1;
    reg [3:0] opcode;
    reg [4:0] ROB_entry;
    reg [4:0] dest_reg;
    reg [4:0] flag_reg;
    reg [7:0] op_a_val;
    reg [7:0] op_b_val;
    reg [7:0] flags_val;

    reg instr_valid;

    wire [4:0] ROB_entry_out;
    wire [4:0] dest_reg_out;
    wire [4:0] flag_reg_out;
    wire [7:0] result_val;
    wire [7:0] result_flags;
    
    arithmetic_pipeline dut (
        .clk(clk),
        .opcode(opcode),
        .ROB_entry(ROB_entry),
        .dest_reg(dest_reg),
        .flag_reg(flag_reg),
        .op_a_val(op_a_val),
        .op_b_val(op_b_val),
        .flags_val(flags_val),
        .instr_valid(.instr_valid),
        .ROB_entry_out(ROB_entry_out),
        .dest_reg_out(dest_reg_out),
        .flag_reg_out(flag_reg_out),
        .result_val(result_val),
        .result_flags(result_flags)
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
        
        opcode = 4'b0000;
        ROB_entry = 5'h1;
        dest_reg = 5'h2;
        flag_reg = 5'hf;
        op_a_val = 8'h1;
        op_b_val = 8'h2;
        flags_val = 8'hFF;
        instr_valid = 1'b1;

        $finish;
    end

endmodule
