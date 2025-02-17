// TODO: WRONG: renamer cell needs to not attempt to rename out of order

module renamer_cell(
        input [3:0] arch_reg,

        input [`PHYS_REGS-3:0] free_pool,
        input [`PR_ADDR_W*10 - 1:0] rat_aliases,
        input [9:0] rat_done,

        output [`PHYS_REGS-3:0] new_free_pool,
        output [`PR_ADDR_W*10 - 1:0] new_rat_aliases,
        output [9:0] new_rat_done,

        output [`PR_ADDR_W-1:0] phys_reg,
        output phys_reg_valid
    );

    wire [`PR_ADDR_W-1:0] chosen_reg;
    wire chosen_reg_valid;
    priority_enc encoder(
        .in(rat_done),
        .any(chosen_reg_valid),
        .out(chosen_reg)
    );

    assign phys_reg = arch_reg == 4'h0 ? 0
                    : arch_reg == 4'h1 ? 1
                    : chosen_reg + 2;

    wire does_rename = arch_reg != 4'h0 & arch_reg != 4'h1;
    assign phys_reg_valid = ~does_rename | chosen_reg_valid;
    
    assign new_free_pool = free_pool & ~(does_rename << (phys_reg-2));
    assign new_rat_aliases = does_rename ?
            rat_aliases & ~({`PR_ADDR_W{1'b1}} << (`PR_ADDR_W*arch_reg))
            | phys_reg << (`PR_ADDR_W*arch_reg)
        : rat_aliases;
    assign new_rat_mask = does_rename ? rat_mask | 1 << arch_reg : rat_mask;
endmodule

module renamer(
        input [23:0] microop,
        input prev_rename_valid,

        input [`PHYS_REGS-3:0] free_pool,
        input [`PR_ADDR_W*10 - 1:0] rat_aliases,
        input [9:0] rat_mask,

        output [`PHYS_REGS-3:0] new_free_pool,
        output [`PR_ADDR_W*10 - 1:0] new_rat_aliases,
        output [9:0] new_rat_mask,

        output [7:0] dst_arch_regs,
        output [2*`PR_ADDR_W-1:0] dst_regs,
        output rename_valid
    );

    reg [7:0] dst_arch; // combinational
    assign dst_arch_regs = dst_arch;

    wire [`PHYS_REGS-3:0] free_pool_carry, free_pool_if_success;
    wire [`PR_ADDR_W*10 - 1:0] rat_aliases_carry, rat_aliases_if_success;
    wire [9:0] rat_mask_carry, rat_mask_if_success;
    wire [1:0] cells_valid;

    renamer_cell renamer_cells [1:0] (
        .arch_reg(dst_arch),

        .free_pool({free_pool, free_pool_carry}),
        .rat_aliases({rat_aliases, rat_aliases_carry}),
        .rat_mask({rat_mask, rat_mask_carry}),

        .new_free_pool({free_pool_carry, free_pool_if_success}),
        .new_rat_aliases({rat_aliases_carry, rat_aliases_if_success}),
        .new_rat_mask({rat_mask_carry, rat_mask_if_success}),

        .phys_reg(dst_regs),
        .phys_reg_valid(cells_valid)
    );
    assign rename_valid = prev_rename_valid & &cells_valid;
    assign new_free_pool = rename_valid ? free_pool_if_success : free_pool;
    assign new_rat_aliases = rename_valid ? rat_aliases_if_success : rat_aliases;
    assign new_rat_mask = rename_valid ? rat_mask_if_success : rat_mask;

    wire [3:0] opcode = microop[23:20];
    // blah blah always @* bad
    always @* case(opcode)
        4'b1100: dst_arch = {4'h0, microop[15:12]}; // load
        4'b1101: dst_arch = 8'h00; // store
        4'b1110, 4'b1111: dst_arch = {`REG_PCH, `REG_PCL}; // terminates
        default: dst_arch = microop[19:12]; // everything else (2 destinations)
    endcase
endmodule