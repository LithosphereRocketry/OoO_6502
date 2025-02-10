/*
Allows 4 inputs per cycle, outputs at most one ready instruction per cycle
*/

module issue_buff_ooo #(
        parameter DATA_WIDTH = 47,
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

        input [9:0] done_flags
    );
    // look into instance array

    reg [ELEMENTS-1:0] valid_mask;
    reg [ELEMENTS-1:0] output_enable_mask;
    reg [ELEMENTS-1:0] write_enable_mask;
    reg [ELEMENTS-1:0] available_mask;
    reg [ELEMENTS*DATA_WIDTH-1:0] instr_inputs;
    reg [ELEMENTS*DATA_WIDTH-1:0] instr_outputs;
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

    integer i;
    reg [$clog2(PUSH_WIDTH):0] din_ready_ct_tmp;

    always @(*) begin
        din_ready_ct_tmp <= 0;
        for(i = 0; i < ELEMENTS; i = i+1) begin
            if(available_mask[i] == 1 & din_ready_ct_tmp < PUSH_WIDTH) din_ready_ct_tmp <= din_ready_ct_tmp + 1;
        end
        din_ready_ct <= din_ready_ct_tmp;
    end

    task reset; begin
        read_ptr <= 0;
        write_ptr <= 0;
    end endtask

    initial reset();

    wire [$clog2(ELEMENTS):0] output_ind;

    priority_enc _find_first_valid #(.WIDTH(ELEMENTS)) (
        .in(valid_mask),
        .any(dout_valid),
        .out(output_ind)
    )

    assign dout = instr_outputs[DATA_WIDTH*(output_ind+1)-1:DATA_WIDTH*output_ind];
    assign output_enable_mask = (dout_ready? (1 << output_ind) : 0)

    integer input_index;
    always @(posedge clk) if(rst) reset(); else begin
        input_index <= 0;
        write_enable_mask = 0;
        for(i = 0; i < ELEMENTS; i = i + 1) begin
            if(input_index < din_valid_ct) begin
                if(available_mask[i] == 1) begin
                    instr_inputs[DATA_WIDTH*(i+1)-1:DATA_WIDTH*i] <= din[DATA_WIDTH*(input_index+1)-1:DATA_WIDTH*input_index];
                    write_enable_mask[i] = 1;
                    input_index <= input_index + 1;
                end
            end
        end
    end

endmodule