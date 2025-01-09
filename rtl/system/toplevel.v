`timescale 1ns/1ps

// Test top level for assembly test cases

module toplevel();
    reg clk = 1;
    wire [7:0] dout;
    wire d_write;
    wire done;

    system dut(
        .clk(clk),
        .dport_out(dout),
        .dport_write(d_write),
        .done(done)
    );

    reg [7:0] datastream [0:255];
    reg [7:0] ds_ptr = 8'h00;

    always @(posedge clk) if(d_write) begin
        datastream[ds_ptr] <= dout;
        ds_ptr <= ds_ptr + 8'd1;
    end

    integer i;
    initial begin
        $dumpfile(`WAVEPATH);
        $dumpvars;

        for(i = 0; i < 256; i++) datastream[i] <= 8'h00;

        repeat(100) begin
            clk = 0;
            #1;
            clk = 1;
            #1;
        end
    end
endmodule