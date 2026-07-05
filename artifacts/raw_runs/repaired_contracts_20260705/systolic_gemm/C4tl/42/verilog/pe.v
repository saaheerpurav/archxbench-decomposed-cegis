module pe(north_in, west_in, clk, rst, south_out, east_out, result);
    input [31:0] north_in, west_in;
    output reg [31:0] south_out, east_out;
    input clk, rst;
    output reg [63:0] result;

    always @(*) begin
        south_out = north_in;
        east_out = west_in;
        result = $signed(north_in) * $signed(west_in);
    end
endmodule