/*

*/

`include "constants.vh"

module decoder_cell(
        input [23:0] logical_instr,
        input rename_valid,
        output logical_instr_ready,  

        input [`PHYS_REGS-3:0] free_pool,
        input [10*`PR_ADDR_W-1:0] rat_aliases,
        input [9:0] rat_done,
        input [29:0] phys_reg_done,
        input [4:0] ROB_entry,

        output [`PHYS_REGS-3:0] free_pool_after,
        output [10*`PR_ADDR_W-1:0] new_rat_aliases,
        output [9:0] new_rat_done,
        output [9:0] old_rat_aliases,

        output [`RENAMED_OP_SZ-1:0] decoded_instr,
        output decoded_instr_valid,
        input decoded_instr_ready
    );

    wire [7:0] arch_regs;
    wire [19:0] src_regs;
    wire [3:0] src_ready;
    wire [3:0] immediate;
    wire [9:0] dest_regs;
    reg [`PHYS_REGS-3:0] free_pool_tmp;
    reg [10*`PR_ADDR_W-1:0] rat_aliases_tmp;

    rename_decoder _rename_decode(
        .microop(logical_instr),
        .rat_done(rat_done),
        .phys_reg_done(phys_reg_done),
        .rat_aliases(rat_aliases),
        .src_regs(src_regs),
        .src_ready(src_ready),
        .immediate(immediate)
    );

    renamer _rename(
        .microop(logical_instr),
        .prev_rename_valid(rename_valid),
        .free_pool(free_pool),
        .rat_aliases(rat_aliases),
        .rat_done(rat_done),
        .new_free_pool(free_pool_after),
        .new_rat_aliases(new_rat_aliases),
        .new_rat_done(new_rat_done),
        .dst_arch_regs(arch_regs),    
        .dst_regs(dest_regs),
        .old_regs(old_rat_aliases),
        .rename_valid(decoded_instr_valid)
    );

    assign logical_instr_ready = decoded_instr_valid & decoded_instr_ready;
    assign decoded_instr = {arch_regs, logical_instr[23:20], 1'b0, ROB_entry, dest_regs, src_regs, src_ready, immediate};

endmodule

module decoder #(
        parameter WIDTH = 4
    ) (
        input clk,
        input rst,

        input [29:0] cmplt_free_regs, // old assignments from committed instructions

        input [19:0] cmplt_dest_regs, // architected regs from completed instructions
        input [5*`PR_ADDR_W-1:0] cmplt_phys_regs,
        input [19:0] ROB_entries_in, // available ROB entries

        input [WIDTH*24-1:0] logical_instrs,
        input logical_instrs_valid,
        output logical_instrs_ready,

        output [`RENAMED_OP_SZ*WIDTH-1:0] decoded_instrs,
        output [8*WIDTH-1:0] decoded_arch_regs,
        output [10*WIDTH-1:0] decoded_old_aliases,
        output reg old_aliases_valid,
        input [WIDTH-1:0] decoded_instrs_ready,
        output [WIDTH-1:0] decoded_instrs_valid
    );

    wire [WIDTH*4-1:0] opcode;
    genvar i;
    for(i = 0; i < WIDTH; i = i + 1)
            assign opcode[4*i +: 4] = logical_instrs[24*i + 20 +: 4];

    reg [3:0] to_be_decoded;

    reg [`PHYS_REGS-3:0] free_pool;
    reg [19:0] ROB_entries;

    wire [9:0] done_flags;
    reg [9:0] done_flags_in; // combinational
    wire [10*`PR_ADDR_W-1:0] assignments, assignments_in;
    rat #(10, `PR_ADDR_W) _rat(
        .clk(clk),
        .rst(rst),
        .assignments_in(assignments_in),
        .done_flags_in(done_flags_in),
        .assignments(assignments),
        .done_flags(done_flags)
    );

    wire [10*`PR_ADDR_W*(WIDTH-1)-1:0] interim_assignments;
    wire [(`PHYS_REGS-2)*(WIDTH-1)-1:0] interim_free_pool;
    wire [10*(WIDTH-1)-1:0] interim_done_flags;
    reg [WIDTH*24-1:0] instructions;
    wire [WIDTH-1:0] decoded_instrs_valid_tmp;
    wire [WIDTH - 1: 0] decoders_logical_instrs_ready;

    wire [10*`PR_ADDR_W-1:0] produced_assignments;
    wire [`PHYS_REGS-3:0] produced_free_pool;
    wire [9:0] produced_done_flags;
    reg [`PHYS_REGS-3:0] phys_reg_done;
    reg [`PHYS_REGS-3:0] phys_reg_done_next; // combinational

    decoder_cell _decoder_cell [WIDTH-1:0] (
        .logical_instr(instructions),
        .rename_valid({1'b1, decoded_instrs_valid_tmp[WIDTH-1:1]}),
        .logical_instr_ready(decoders_logical_instrs_ready),  

        .free_pool({free_pool, interim_free_pool}),
        .rat_aliases({assignments, interim_assignments}),
        .rat_done({done_flags, interim_done_flags}),
        .phys_reg_done(phys_reg_done),
        .ROB_entry(ROB_entries),

        .free_pool_after({interim_free_pool, produced_free_pool}),
        .new_rat_aliases({interim_assignments, produced_assignments}),
        .new_rat_done({interim_done_flags, produced_done_flags}),
        .old_rat_aliases(decoded_old_aliases),

        .decoded_instr(decoded_instrs),
        .decoded_instr_valid(decoded_instrs_valid_tmp),
        .decoded_instr_ready(decoded_instrs_ready)
    );

    task reset; begin
        free_pool <= {`PHYS_REGS{1'b1}};
        instructions <= 0;
        to_be_decoded <= 0;
        free_pool_to_set <= 0;
        phys_reg_done <= 0;
    end endtask

    initial reset();

    // // TODO ASSIGN THINGS
    // assign interim_assignments[10*`PR_ADDR_W*WIDTH-1 +: 10*`PR_ADDR_W] = assignments;
    // assign interim_free_pool[`PHYS_REGS*WIDTH-1 +: `PHYS_REGS] = free_pool;
    // assign interim_done_flags[10*WIDTH-1 +: 10] = done_flags;

    reg [29:0] free_pool_tmp;
    reg [29:0] free_pool_to_set;

    // set done flags for completed instructions
    integer j;
    always @(*) begin
        done_flags_in = (logical_instrs_valid & logical_instrs_ready) ? produced_done_flags : done_flags;
        free_pool_tmp = ((logical_instrs_valid & logical_instrs_ready) ? produced_free_pool : free_pool);
        for(j = 0; j < 6; j = j + 1) begin
            if (cmplt_free_regs[5*j +: 5] > 1) free_pool_tmp |= 1 << (cmplt_free_regs[5*j +: 5]-2);
            if(j < 5) done_flags_in[cmplt_dest_regs[4*j +: 4]] = 1;
        end
    end

    assign decoded_instrs_valid = {WIDTH{&decoded_instrs_valid_tmp}} & to_be_decoded;

    wire [WIDTH-1:0] to_be_decoded_next =
            to_be_decoded & ~(decoded_instrs_ready & decoded_instrs_valid);
    
    reg [`PR_ADDR_W-1:0] cmplt_tmp; // combinational
    always @* begin
        phys_reg_done_next = phys_reg_done;
        for(j = 0; j < 5; j = j + 1) begin
            cmplt_tmp = cmplt_phys_regs[`PR_ADDR_W*j +: `PR_ADDR_W];
            if(cmplt_tmp >= 2) phys_reg_done_next[cmplt_tmp-2] = 1;
        end
    end

    assign logical_instrs_ready = to_be_decoded_next == 0;
    always @(posedge clk) if(rst) reset(); else begin
        if(logical_instrs_valid & logical_instrs_ready) begin
            instructions <= logical_instrs;
            to_be_decoded <= {WIDTH{1'b1}};
            free_pool <= free_pool_tmp;
            old_aliases_valid <= 1;
            ROB_entries <= ROB_entries_in;
            phys_reg_done <= 0;
        end else begin
            to_be_decoded <= to_be_decoded_next;
            old_aliases_valid <= 0;
            phys_reg_done <= phys_reg_done_next;
        end
    end

endmodule