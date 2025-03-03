/*
Allows 4 inputs per cycle, outputs at most one ready instruction per cycle
*/

module issue_buffer_ooo #(
        parameter DATA_WIDTH = `RENAMED_OP_SZ,
        parameter PUSH_WIDTH = 4,
        parameter ELEMENTS = 4
    ) (
        input clk,
        input rst,
        input [DATA_WIDTH*PUSH_WIDTH-1:0] din,
        input [$clog2(PUSH_WIDTH):0] din_valid_ct,
        output [$clog2(PUSH_WIDTH):0] din_ready_ct,

        output [DATA_WIDTH-1:0] dout,
        output dout_valid,
        input dout_ready,

        input [29:0] done_flags
    );
    // look into instance array

    wire [ELEMENTS-1:0] valid_mask;
    wire [ELEMENTS-1:0] output_enable_mask;
    reg [ELEMENTS-1:0] write_enable_mask;
    wire [ELEMENTS-1:0] available_mask;
    reg [ELEMENTS*DATA_WIDTH-1:0] instr_inputs;
    wire [ELEMENTS*DATA_WIDTH-1:0] instr_outputs;
    wire full;
    issue_entry_capped entries [ELEMENTS-1:0] (
        .clk(clk),
        .rst(rst),
        .done_flags(done_flags),
        .instr(instr_inputs),
        .input_valid(write_enable_mask),
        .output_ready(output_enable_mask),

        .instr_out(instr_outputs),
        .input_ready(available_mask),
        .output_valid(valid_mask)
    );
    
    assign full = (available_mask == 0);

    integer input_index;
    integer i;
    reg [$clog2(PUSH_WIDTH):0] din_ready_ct_tmp;

    always @(*) begin
        din_ready_ct_tmp = 0;
        for(i = 0; i < ELEMENTS; i = i+1) begin
            if(available_mask[i] == 1 & din_ready_ct_tmp < PUSH_WIDTH) din_ready_ct_tmp = din_ready_ct_tmp + 1;
        end
        input_index = 0;
        write_enable_mask = 0;
        for(i = 0; i < ELEMENTS; i = i + 1) begin
            if(input_index < din_valid_ct) begin
                if(available_mask[i] == 1) begin
                    instr_inputs[DATA_WIDTH*i +:DATA_WIDTH] = din[DATA_WIDTH*input_index +:DATA_WIDTH];
                    write_enable_mask[i] = 1;
                    input_index = input_index + 1;
                end
            end
        end
    end
    assign din_ready_ct = din_ready_ct_tmp;

    task reset; begin

    end endtask

    initial reset();

    wire [$clog2(ELEMENTS)-1:0] output_ind;

    priority_enc #(.WIDTH(ELEMENTS)) _find_first_valid (
        .in(valid_mask),
        .any(dout_valid),
        .out(output_ind)
    );

    assign dout = instr_outputs[DATA_WIDTH*output_ind +:DATA_WIDTH];
    assign output_enable_mask = ((dout_ready & dout_valid) ? (1 << output_ind) : 0);

endmodule