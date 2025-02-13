/*

*/

`include "constants.vh"

module decoder_cell(
        input [23:0] logical_instr,
        input logical_instr_valid,
        output logical_instr_ready,  

        input [`PHYS_REGS-3:0] free_pool,
        input [10*`PR_ADDR_W-1] rat_aliases,
        input [9:0] rat_done,
        input [4:0] ROB_entry,

        output [`PHYS_REGS-3:0] free_pool_after,
        output [10*`PR_ADDR_W-1] new_rat_aliases,
        output [9:0] old_rat_aliases,

        output [`RENAMED_OP_SZ-1:0] decoded_instr,
        output decoded_instr_valid,
        input decoded_instr_ready
    );

    wire [19:0] src_regs;
    wire [3:0] src_ready;
    wire [3:0] immediate;
    reg [9:0] dest_regs, old_rat_aliases_tmp;
    reg [`PHYS_REGS-3:0] free_pool_tmp;
    reg [10*`PR_ADDR_W-1] rat_aliases_tmp;

    rename_decoder _decode(
        .microop(logical_instr),
        .rat_done(rat_done),
        .rat_aliases(rat_aliases),
        .src_regs(src_regs),
        .immediate(imm)
    );

    assign logical_instr_ready = !decoded_instr_valid | decoded_instr_ready;
    assign new_rat_aliases = rat_aliases_tmp;
    assign free_pool_after = free_pool_tmp;
    assign decoded_instr = {logical_instr[23:20], dest_regs, src_regs, src_ready, immediate, ROB_entry};
    assign old_rat_aliases = old_rat_aliases_tmp;

    integer i;
    integer to_assign;
    integer num_assign;
    always@(*) begin
        if(logical_instr_valid & logical_instr_ready) begin
            to_assign = 0;
            free_pool_tmp = free_pool;
            rat_aliases_tmp = rat_aliases;
            old_rat_aliases_tmp = {10{1'b0}};
            dest_regs = {10{1'b0}};
            if (logical_instr[23:20] == 0'b1100) num_assign = 1;
            else if (logical_instr[23:22] == 0'11) num_assign = 0;
            else num_assign = 2;
            for(i = 0; i < `PHYS_REGS-2; i = i + 1) if(to_assign < num_assign) begin
                while((logical_instr[11+4*to_assign +: 4] == 4'b0 | logical_instr[11+4*to_assign +: 4] == 4'b1) & to_assign < num_assign) begin
                    to_assign = to_assign + 1;
                end
                if(free_pool_tmp[i] & to_assign < num_assign) begin
                    dest_regs[to_assign*5-1 +: 5] = i+2;
                    free_pool_tmp[i] = 0;
                    old_rat_aliases_tmp[to_assign*5-1 +: 5] = rat_aliases_tmp[logical_instr[11+4*to_assign +: 4] - 2];
                    rat_aliases_tmp[logical_instr[11+4*to_assign +: 4] - 2] = i+2;
                    to_assign = to_assign + 1;
                end
            end
            if(to_assign < num_assign) begin
                decoded_instr_valid = 0;
            end else decoded_instr_valid = 1;
        end
    end

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
        input [WIDTH-1:0] logical_instrs_valid,
        output logical_instrs_ready,

        output [`RENAMED_OP_SZ*WIDTH-1:0] decoded_instrs,
        input [WIDTH-1:0] decoded_instrs_ready,
        output [WIDTH-1:0] decoded_instrs_valid,

        output [39:0] old_aliases
    );

    wire [WIDTH*4-1:0] opcode;
    genvar i;
    for(i = 0; i < WIDTH; i = i + 1)
            assign opcode[4*i +: 4] = logical_instrs[24*i + 20 +: 4];

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
    reg [WIDTH*24-1:0] instructions;
    reg [WIDTH-1:0] decoded_instrs_valid_tmp;

    decoder_cell [WIDTH-1:0] _decoders (
        .logical_instr(instructions),
        .logical_instr_valid(logical_instrs_valid),
        .logical_instr_ready(logical_instrs_ready),  

        .free_pool(interim_free_pool[`PHYS_REGS*(WIDTH+1)-1:`PHYS_REGS]),
        .rat_aliases(interim_assignments[10*`PR_ADDR_W*(WIDTH+1)-1:10*`PR_ADDR_W*WIDTH]),
        .rat_done(done_flags),
        .ROB_entry(ROB_entries),

        .free_pool_after(interim_free_pool[`PHYS_REGS*WIDTH-1:0]),
        .new_rat_aliases(interim_assignments[10*`PR_ADDR_W*WIDTH-1:0]),
        .old_rat_aliases(old_aliases),

        .decoded_instr(decoded_instrs),
        .decoded_instr_valid(decoded_instrs_valid_tmp),
        .decoded_instr_ready(decoded_instrs_ready)
    );

    task reset; begin
        free_pool <= {`PHYS_REGS{1'b1}};
    end endtask

    initial reset();

    // TODO ASSIGN THINGS
    assign interim_assignments[10*`PR_ADDR_W*(WIDTH+1)-1 +: 10*`PR_ADDR_W] = assignments;
    assign interim_free_pool[`PHYS_REGS*(WIDTH+1)-1 +: `PHYS_REGS] = free_pool;

    //assign assignments_in = interim_assignments[10*`PR_ADDR_W-1:0];
    //assign done_flags_in = done_flags;

    integer i;
    always @(*) begin
        done_flags_in = done_flags;
        for(i = 0; i < 6; i = i + 1) begin
            if (cmplt_free_regs[5*(i+1)-1 +: 5] > 1) free_pool[cmplt_free_regs[5*(i+1)-1 +: 5]-2] = 1;
            done_flags_in[cmplt_dest_regs[4*(i+1)-1 +: 4]] = 1;
        end
    end

    integer last_valid;
    always @(posedge clk) if(rst) reset(); else begin
        last_valid = 4;
        for(i = 0; i < 4; i = i + 1) if(decoded_instrs_valid[3-i] & decoded_instrs_ready[3-i]) begin
            last_valid = last_valid - 1;
        end

        assignments_in = interim_assignments[10*`PR_ADDR_W*(last_valid + 1)-1 +: 10*`PR_ADDR_W];
        free_pool = interim_free_pool[`PHYS_REGS*(last_valid+1)-1 +: `PHYS_REGS];

        if(last_valid > 0) begin
            instructions = instructions << (last_valid * 24);
            for(i = 0; i < last_valid; i = i + 1) decoded_instr_valid_tmp[i] = 0;
            logical_instrs_ready = 0;
        end else begin
            logical_instrs_ready = 1;
        end
        decoded_instrs_valid = decoded_instrs_valid_tmp;
    end

endmodule