`timescale 1ns/1ps

// Test top level for assembly test cases

module toplevel();
    localparam MAX_CYCLES = 10;

    reg clk = 1, reset = 1;
    wire [7:0] dout;
    wire d_write;
    wire done;

    integer count = 0;
    integer i;
    
    system dut(
        .clk(clk),
        .rst(reset),
        .dport_out(dout),
        .dport_write(d_write),
        .done(done)
    );

    reg [7:0] correct_datastream [0:255];
    reg [7:0] datastream [0:255];

    reg [8:0] ds_ptr = 9'h00; // One extra bit to check if we've iterated off the end

    always #1 clk = ~clk;

    always @(posedge clk) begin
        if(reset) begin
            reset <= 0;
        end else if(count >= MAX_CYCLES) begin
            $display("Simulation timed out");
            $fatal;
        end else if(done) begin
            for(i = 0; i < 9'h100; i++) begin
                if(correct_datastream[i] !== datastream[i]) begin
                    $display("Error in assembly output: expected %h at %h, got %h",
                            correct_datastream[i], i, datastream[i]);
                    $fatal;
                end
            end
            $display("Program completed in %d cycles", count);
            $finish;
        end else begin
            count ++;
            if(d_write) begin
                if(ds_ptr <= 8'hff) begin
                    datastream[ds_ptr] <= dout;
                    ds_ptr <= ds_ptr + 8'd1;
                end
            end
        end
    end

    initial begin
        $readmemh(`VERIFYPATH, correct_datastream);
        $dumpfile(`WAVEPATH);
        $dumpvars;

        for(i = 0; i < 256; i++) datastream[i] <= 8'hxx;
    end
endmodule