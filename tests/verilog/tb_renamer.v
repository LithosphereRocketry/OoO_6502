`include "constants.vh"

module tb_renamer();
    task assert;
        input [63:0] data;
        input [63:0] expected;
        begin
            if(data !== expected) begin
                $display("Error: expected %h, got %h", expected, data);
                #2;
                $fatal;
            end
        end
    endtask

    reg [23:0] microop;
    reg prev_rename_valid;
    reg [`PHYS_REGS-3:0] free_pool;
    reg [`PR_ADDR_W*10 - 1:0] rat_aliases;
    reg [9:0] rat_done;

    wire [`PHYS_REGS-3:0] new_free_pool;
    wire [`PR_ADDR_W*10 - 1:0] new_rat_aliases;
    wire [9:0] new_rat_done;

    wire [7:0] dst_arch_regs;
    wire [2*`PR_ADDR_W-1:0] dst_regs;
    wire [2*`PR_ADDR_W-1:0] old_regs;
    wire rename_valid;

    renamer dut(
        .microop(microop),
        .prev_rename_valid(prev_rename_valid),
        .free_pool(free_pool),
        .rat_aliases(rat_aliases),
        .rat_done(rat_done),
        .new_free_pool(new_free_pool),
        .new_rat_aliases(new_rat_aliases),
        .new_rat_done(new_rat_done),
        .dst_arch_regs(dst_arch_regs),
        .dst_regs(dst_regs),
        .old_regs(old_regs),
        .rename_valid(rename_valid)
    );

    initial begin
        $dumpfile(`WAVEPATH);
        $dumpvars;

        prev_rename_valid = 1;
        
        // basic renaming: add into r3 and r4
        microop = 24'h034123;
        // Free registers: p4, p5, p9, p11, p12
        free_pool = 30'b00000000_00000000_00011010_001100;
        // Previous mappings
        rat_aliases = {5'd31, 5'd30, 5'd29, 5'd28, 5'd27,
                       5'd26, 5'd25, 5'd24, 5'd23, 5'd22};
        // assume everyone else is done
        rat_done = {10'b1111111111};

        #1;

        assert(new_free_pool, 30'b00000000_00000000_00011010_000000);
        assert(new_rat_aliases, {5'd31, 5'd30, 5'd29, 5'd28, 5'd27,
                                 5'd26, 5'd25, 5'd5, 5'd4, 5'd22});
        assert(new_rat_done, {10'b1111111001});
        assert(dst_arch_regs, {4'h3, 4'h4});
        assert(dst_regs, {5'd4, 5'd5});
        assert(old_regs, {5'd23, 5'd24});
        assert(rename_valid, 1);

        // test propagation of rename fails
        prev_rename_valid = 0;
        #1;
        assert(rename_valid, 0);

        // test fail on out-of-registers
        prev_rename_valid = 1;
        free_pool = 30'b00000000_00000000_00000000_000100;
        #1;
        assert(rename_valid, 0);
    end
endmodule