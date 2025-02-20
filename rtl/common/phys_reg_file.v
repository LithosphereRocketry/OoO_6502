module phys_reg_file(
    input clk,
    input rst,

    input [5*12-1:0] read_addrs,
    input [5*6-1:0] write_addrs,
    input [8*6-1:0] write_vals,

    output [8*12-1:0] read_vals
);

wire [30*8-1:0] regs;

task reset; begin
    regs = {30*8-1{1'b0}};
end endtask

genvar k;
for(k = 0; k < 12; k = k + 1) begin
    if(read_addrs[k*5 +: 5] == 0) assign read_vals[k*8 +: 8] = 8'b0;
    else if(read_addrs[k*5 +: 5] == 1) assign read_vals[k*8 +: 8] = 8'h01;
    else assign read_vals[k*8+:8] = regs[(read_addrs[k*5 +: 5]-2)*8 +: 8];
end

integer i;
always @(posedge clk) if(rst) reset(); else begin
    for(i = 0; i < 6; i = i + 1) begin
        if(write_addrs[5*i +: 5] > 1) begin
            regs[write_addrs[5*i +: 5]-2] = write_vals[8*i +: 8];
        end
    end
end

endmodule