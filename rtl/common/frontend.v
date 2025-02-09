module frontend(
        input clk,
        input rst
    );

    localparam ISSUE_WIDTH = 4;
    
    uop_fetch #(ISSUE_WIDTH) fetch (
        .clk(clk),
        .rst(rst),
        .fetch(0),
        .macroop_in(8'hxx),
        .microops_ready(1)
    );


endmodule