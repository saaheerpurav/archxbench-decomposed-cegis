module gs_reciprocal #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input  signed [DATA_WIDTH-1:0] a,
    output reg signed [DATA_WIDTH-1:0] reciprocal
);

    localparam integer NUM_WIDTH =
        ((2*DATA_WIDTH + 2) > (2*FRAC + 2)) ? (2*DATA_WIDTH + 2) : (2*FRAC + 2);

    reg signed [NUM_WIDTH-1:0] numerator;
    reg signed [NUM_WIDTH-1:0] denominator;
    reg signed [NUM_WIDTH-1:0] quotient;

    always @* begin
        numerator   = {{(NUM_WIDTH-1){1'b0}}, 1'b1} << (2*FRAC);
        denominator = {{(NUM_WIDTH-DATA_WIDTH){a[DATA_WIDTH-1]}}, a};

        if (a == {DATA_WIDTH{1'b0}}) begin
            reciprocal = {DATA_WIDTH{1'b0}};
        end else begin
            quotient = numerator / denominator;
            reciprocal = quotient[DATA_WIDTH-1:0];
        end
    end

endmodule