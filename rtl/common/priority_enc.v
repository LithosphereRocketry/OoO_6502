/*
Gives the position of the least-significant high bit in a word

Width is based on input, so output is $clog2(WIDTH) bits
*/

module priority_enc #(parameter WIDTH = 8) (
        input [WIDTH-1:0] in,
        output any,
        output [$clog2(WIDTH)-1:0] out
    );

    reg tmp_any; // combinational
    assign any = tmp_any;
    reg [$clog2(WIDTH)-1:0] tmp_out;
    assign out = tmp_out;

    integer i;
    // I kinda hate always @* but it makes life easier here
    always @* begin
        tmp_any = 0;
        tmp_out = {WIDTH{1'bx}};
        for(i = 0; i < WIDTH; i = i+1) begin
            if(~tmp_any & in[i]) begin
                tmp_any = 1;
                tmp_out = i;
            end
        end
    end
endmodule