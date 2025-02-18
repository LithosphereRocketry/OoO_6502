module memory_pipeline(
    input clk,
    input [4:0] mem_opcode,
    input [15:0] base_val,
    input [7:0] offset,
    input [4:0] dest_reg,
    input [7:0] data,
    input [3:0] imm,
    input input_valid,
    output input_ready,

    output [15:0] mem_addr,
    output [4:0] dest_reg_out,
    output [7:0] data_out,
    output store_out,
    output output_valid,
    input output_ready
);

assign input_ready = !output_valid | output_ready;

integer lower_bits;

always @(posedge clk) begin
    if(input_valid & input_ready) begin
        if(imm[3]) begin
            lower_bits = base_val[7:0] + offset;
            mem_addr <= {base_val[15:8], lower_bits[7:0]};
        end
        else mem_addr <= base_val + offset;
        dest_reg_out <= dest_reg;
        data_out <= data;
        store_out <= store;
        output_valid = 1;
    end
    else output_valid = 0;
end
endmodule