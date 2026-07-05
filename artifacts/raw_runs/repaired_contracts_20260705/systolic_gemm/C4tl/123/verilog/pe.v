module pe(north_in, west_in, clk, rst, south_out, east_out, result);
    input [31:0] north_in, west_in;
    input clk, rst;
    output reg [31:0] south_out, east_out;
    output reg [63:0] result;

    wire signed [31:0] signed_north;
    wire signed [31:0] signed_west;
    wire signed [63:0] signed_product;

    assign signed_north = north_in;
    assign signed_west = west_in;
    assign signed_product = signed_north * signed_west;

    always @(*) begin
        south_out = north_in;
        east_out = west_in;
        result = signed_product;
    end
endmodule