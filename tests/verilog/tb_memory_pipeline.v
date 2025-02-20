`timescale 1ns/1ps

module tb_memory_pipeline();

    reg clk = 1;
    reg [4:0] mem_opcode;
    reg [15:0] base_val;
    reg [7:0] offset;
    reg [4:0] dest_reg;
    reg [7:0] data;
    reg store;
    reg input_valid;

    wire input_ready;
    wire [15:0] mem_addr;
    wire [4:0] dest_reg_out;
    wire [7:0] data_out;
    wire store_out;
    wire output_valid;
    reg output_ready;

    
    memory_pipeline dut (
        .clk(clk),
        .mem_opcode(mem_opcode),
        .base_val(base_val),
        .offset(offset),
        .dest_reg(dest_reg),
        .data(data),
        .store(store),
        .input_valid(input_valid),
        .input_ready(input_ready),
        .mem_addr(mem_addr),
        .dest_reg_out(dest_reg_out),
        .data_out(data_out),
        .store_out(store_out),
        .output_valid(output_valid),
        .output_ready(output_ready)
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
        
        mem_opcode;
        base_val;
        offset;
        dest_reg;
        data;
        store;
        input_valid;
        output_ready;

        $finish;
    end

endmodule
