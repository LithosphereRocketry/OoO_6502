module uop_fetch #(
        parameter FETCH_WIDTH = 4
    ) (
        input clk,
        input rst,
        input fetch,
        input [7:0] macroop_in,

        input microops_ready,
        output [24*FETCH_WIDTH-1:0] microops
    );

    localparam UCR_PARALLEL_WIDTH = `UCR_ADDR_WIDTH - $clog2(FETCH_WIDTH);

    reg [24*FETCH_WIDTH-1:0] uop_rom [0:(1<<UCR_PARALLEL_WIDTH)-1];
    initial $readmemh("rom/microcode.hex", uop_rom);

    wire [`UCR_ADDR_WIDTH-1:0] uop_pc;

    uop_fetch_ctrl #(
        .UCR_ADDR_WIDTH(`UCR_ADDR_WIDTH),
        .FETCH_WIDTH(FETCH_WIDTH)
    ) fetch_ctrl (
        .rst(rst),
        .clk(clk),
        .macro_fetch(fetch),
        .macroop(macroop_in),

        .uop_pc_ready(microops_ready),
        .uop_pc(uop_pc)
    );

    assign microops = uop_rom[uop_pc >> $clog2(FETCH_WIDTH)];

    always @(negedge clk) if(uop_pc & (FETCH_WIDTH-1) != 0) begin
        $display("Tried to decode a macroop with no translation!");
        $fatal;
    end

endmodule