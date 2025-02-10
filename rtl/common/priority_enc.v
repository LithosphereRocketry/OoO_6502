/*
Gives the position of the least-significant high bit in a word

Width is based on input, so output is $clog2(WIDTH) bits
*/

module priority_enc #(parameter WIDTH = 8) (
        input [WIDTH-1:0] in,
        output any,
        output [$clog2(WIDTH)-1:0] out
    );

    integer i;
    // I kinda hate always @* but it makes life easier here
    always @* begin
        any = 0;
        for(i = 0; i < WIDTH; i = i+1) begin
            if(~any & in[i]) begin
                any = 1;
                out = i;
            end
        end
    end
endmodule