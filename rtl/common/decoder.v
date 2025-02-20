/*

*/

`include "constants.vh"

module decoder_cell(
        input [23:0] logical_instr,
        input logical_instr_valid,
        input rename_valid,
        output logical_instr_ready,  

        input [`PHYS_REGS-3:0] free_pool,
        input [10*`PR_ADDR_W-1:0] rat_aliases,
        input [9:0] rat_done,
        input [4:0] ROB_entry,

        output [`PHYS_REGS-3:0] free_pool_after,
        output [10*`PR_ADDR_W-1:0] new_rat_aliases,
        output [9:0] new_rat_done,
        output [9:0] old_rat_aliases,
        output [7:0] arch_regs,

        output [`RENAMED_OP_SZ-1:0] decoded_instr,
        output decoded_instr_valid,
        input decoded_instr_ready
    );

    wire [19:0] src_regs;
    wire [3:0] src_ready;
    wire [3:0] immediate;
    reg [9:0] dest_regs, old_rat_aliases_tmp;
    reg [`PHYS_REGS-3:0] free_pool_tmp;
    reg [10*`PR_ADDR_W-1:0] rat_aliases_tmp;

    rename_decoder _rename_decode(
        .microop(logical_instr),
        .rat_done(rat_done),
        .rat_aliases(rat_aliases),
        .src_regs(src_regs),
        .immediate(imm)
    );

    renamer _rename(
        .microop(logical_instr),
        .microop_valid(logical_instr_valid),
        .prev_rename_valid(rename_valid),
        .free_pool(free_pool),
        .rat_aliases(rat_aliases),
        .rat_mask(rat_done),
        .new_free_pool(free_pool_after),
        .new_rat_aliases(new_rat_aliases),
        .new_rat_mask(new_rat_done),
        .dst_arch_regs(arch_regs),    
        .dst_regs(dest_regs),
        .old_regs(old_rat_aliases),
        .rename_valid(decoded_instr_valid)
    );

    assign logical_instr_ready = !decoded_instr_valid | decoded_instr_ready;
    assign decoded_instr = {logical_instr[23:20], dest_regs, src_regs, src_ready, immediate, ROB_entry};

endmodule

module decoder #(
        parameter WIDTH = 4
    ) (
        input clk,
        input rst,

        input [29:0] cmplt_free_regs, // old assignments from committed instructions

        input [23:0] cmplt_dest_regs, // physical regs from completed instructions
        input [19:0] ROB_entries, // available ROB entries

        input [WIDTH*24-1:0] logical_instrs,
        input logical_instrs_valid,
        output logical_instrs_ready,

        output [`RENAMED_OP_SZ*WIDTH-1:0] decoded_instrs,
        output [8*WIDTH-1:0] decoded_arch_regs,
        output [10*WIDTH-1:0] decoded_old_aliases,
        input [WIDTH-1:0] decoded_instrs_ready,
        output [WIDTH-1:0] decoded_instrs_valid
    );

    wire [WIDTH*4-1:0] opcode;
    genvar i;
    for(i = 0; i < WIDTH; i = i + 1)
            assign opcode[4*i +: 4] = logical_instrs[24*i + 20 +: 4];

    reg [3:0] to_be_decoded;

    reg [`PHYS_REGS-1:0] free_pool;

    wire [9:0] done_flags, done_flags_in;
    wire [10*`PR_ADDR_W-1:0] assignments, assignments_in;
    rat #(10, `PR_ADDR_W) _rat(
        .clk(clk),
        .rst(rst),
        .assignments_in(assignments_in),
        .done_flags_in(done_flags_in),
        .assignments(assignments),
        .done_flags(done_flags)
    );

    wire [10*`PR_ADDR_W*(WIDTH+1)-1:0] interim_assignments;
    wire [`PHYS_REGS*(WIDTH+1)-1:0] interim_free_pool;
    wire [10*(WIDTH+1)-1:0] interim_done_flags;
    reg [WIDTH*24-1:0] instructions;
    reg [WIDTH-1:0] decoded_instrs_valid_tmp;
    wire [WIDTH - 1: 0] decoders_logical_instrs_ready;

    decoder_cell _decoder [WIDTH-1:0] (
        .logical_instr(instructions),
        .logical_instr_valid(to_be_decoded),
        .rename_valid({1, decoded_instrs_valid_tmp[WIDTH-1:1]}),
        .logical_instr_ready(decoders_logical_instrs_ready),  

        .free_pool(interim_free_pool[`PHYS_REGS*(WIDTH+1)-1:`PHYS_REGS]),
        .rat_aliases(interim_assignments[10*`PR_ADDR_W*(WIDTH+1)-1:10*`PR_ADDR_W*WIDTH]),
        .rat_done(interim_done_flags[10*(WIDTH+1)-1:10]),
        .ROB_entry(ROB_entries),

        .free_pool_after(interim_free_pool[`PHYS_REGS*WIDTH-1:0]),
        .new_rat_aliases(interim_assignments[10*`PR_ADDR_W*WIDTH-1:0]),
        .new_rat_done(interim_done_flags[10*WIDTH-1:0]),
        .old_rat_aliases(decoded_old_aliases),
        .arch_regs(decoded_arch_regs),

        .decoded_instr(decoded_instrs),
        .decoded_instr_valid(decoded_instrs_valid_tmp),
        .decoded_instr_ready(decoded_instrs_ready)
    );

    task reset; begin
        free_pool <= {`PHYS_REGS{1'b1}};
        logical_instrs_ready = 1;
        instructions = 0;
    end endtask

    initial reset();

    // TODO ASSIGN THINGS
    assign interim_assignments[10*`PR_ADDR_W*(WIDTH+1)-1 +: 10*`PR_ADDR_W] = assignments;
    assign interim_free_pool[`PHYS_REGS*(WIDTH+1)-1 +: `PHYS_REGS] = free_pool;
    assign interim_done_flags[10*(WIDTH+1)-1 +: 10] = done_flags;

    //assign assignments_in = interim_assignments[10*`PR_ADDR_W-1:0];
    //assign done_flags_in = done_flags;

    // set done flags for completed instructions
    integer j;
    always @(*) begin
        done_flags_in = interim_done_flags[9:0];
        for(j = 0; j < 6; j = j + 1) begin
            if (cmplt_free_regs[5*(j+1)-1 +: 5] > 1) free_pool[cmplt_free_regs[5*(j+1)-1 +: 5]-2] = 1;
            done_flags_in[cmplt_dest_regs[4*(j+1)-1 +: 4]] = 1;
        end
    end

    assign decoded_instr_valid = decoded_instrs_valid_tmp & to_be_decoded;
    genvar x;
    for(x = 0; x < WIDTH; x = x + 1)
        if(~decoded_instrs_valid_tmp > (1<<x))
            assign decoded_instrs_valid_tmp[x] = 0;

    integer last_valid;
    integer reached_invalid;
    integer k;
    always @(posedge clk) if(rst) reset(); else begin
        if(logical_instrs_valid & logical_instrs_ready) begin
            instructions = logical_instrs;
            to_be_decoded = {4{logical_instrs_valid}};
        end

        if(decoders_logical_instrs_ready != 4'b1111) logical_instrs_ready <= 0;
        else logical_instrs_ready <= 1;
    end

endmodule