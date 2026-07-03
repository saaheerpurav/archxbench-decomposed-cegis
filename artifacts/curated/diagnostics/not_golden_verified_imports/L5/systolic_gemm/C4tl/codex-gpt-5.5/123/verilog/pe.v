module pe(north_in, west_in, clk, rst, south_out, east_out, result);
    input [31:0] north_in, west_in;
    output reg [31:0] south_out, east_out;
    input clk, rst;
    output reg [63:0] result;

    always @(posedge clk) begin
        if (rst) begin
            south_out <= 32'd0;
            east_out  <= 32'd0;
            result    <= 64'd0;
        end else begin
            south_out <= north_in;
            east_out  <= west_in;
            result    <= result + ({32'd0, north_in} * {32'd0, west_in});
        end
    end
endmodule