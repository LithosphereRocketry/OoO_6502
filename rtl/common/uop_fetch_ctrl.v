module uop_fetch_ctrl #(
        parameter UCR_ADDR_WIDTH = 8,
        parameter ISSUE_WIDTH = 4
    ) (
        input rst,
        input clk,
        input macro_fetch,
        input [7:0] macroop,

        input uop_pc_ready,
        output [UCR_ADDR_WIDTH-1:0] uop_pc
    );

    reg [UCR_ADDR_WIDTH-1:0] uc_offsets [0:8'hff];
    initial $readmemh("rom/microcode_offsets.hex", uc_offsets);

    wire [UCR_ADDR_WIDTH-1:0] incoming_offset = uc_offsets[macroop];

    reg [UCR_ADDR_WIDTH-1:0] step_pc;

    task reset; begin
        step_pc <= 0;
    end endtask
    initial reset();

    assign uop_pc = macro_fetch ? incoming_offset : step_pc;

    always @(posedge clk) if(rst) reset();
                          else if(uop_pc_ready) step_pc <= uop_pc + ISSUE_WIDTH;
endmodule