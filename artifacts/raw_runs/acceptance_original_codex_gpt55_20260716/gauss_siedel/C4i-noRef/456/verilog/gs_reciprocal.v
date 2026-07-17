module gs_reciprocal #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input  [DATA_WIDTH-1:0] a,
    output reg [DATA_WIDTH-1:0] inv
);

    localparam integer NUM_WIDTH =
        ((2 * FRAC + 1) > (2 * DATA_WIDTH)) ? (2 * FRAC + 1) : (2 * DATA_WIDTH);

    reg [NUM_WIDTH-1:0] numerator;
    reg [DATA_WIDTH-1:0] abs_a;
    reg [NUM_WIDTH-1:0] quotient_abs;
    reg sign;

    always @(*) begin
        numerator = {{(NUM_WIDTH-1){1'b0}}, 1'b1} << (2 * FRAC);

        if (a == {DATA_WIDTH{1'b0}}) begin
            inv = {DATA_WIDTH{1'b0}};
        end else begin
            sign = a[DATA_WIDTH-1];

            if (sign)
                abs_a = (~a) + {{(DATA_WIDTH-1){1'b0}}, 1'b1};
            else
                abs_a = a;

            quotient_abs = numerator / abs_a;

            if (sign)
                inv = (~quotient_abs[DATA_WIDTH-1:0]) + {{(DATA_WIDTH-1){1'b0}}, 1'b1};
            else
                inv = quotient_abs[DATA_WIDTH-1:0];
        end
    end

endmodule