module phys_reg_file(
    input clk,
    input rst,

    input [5*12-1:0] read_addrs,
    input [5*6-1:0] write_addrs,
    input [8*6-1:0] write_vals,
    input [5:0] write_enable,

    output [8*12-1:0] read_vals
);

reg [30*8-1:0] regs;

task reset; begin
    regs <= {30*8-1{1'bx}};
end endtask

genvar k;
for(k = 0; k < 12; k = k + 1) begin
    assign read_vals[k*8 +: 8] = read_addrs[k*5 +: 5] == 0 ? 8'h00
                               : read_addrs[k*5 +: 5] == 1 ? 8'h01
                               : regs[(read_addrs[k*5 +: 5]-2)*8 +: 8];
end

integer i;
always @(posedge clk) if(rst) reset(); else begin
    for(i = 0; i < 6; i = i + 1) begin
        if(write_addrs[5*i +: 5] >= 2 & write_enable[i]) begin
            regs[8*(write_addrs[5*i +: 5]-2) +: 8] <= write_vals[8*i +: 8];
        end
    end
end

endmodule