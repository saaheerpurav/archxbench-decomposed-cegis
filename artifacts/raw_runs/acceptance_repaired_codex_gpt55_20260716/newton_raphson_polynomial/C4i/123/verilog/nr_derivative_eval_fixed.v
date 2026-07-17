module nr_derivative_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8
)(
    input signed [WIDTH-1:0] x,
    input signed [WIDTH-1:0] coeff1,
    input signed [WIDTH-1:0] coeff2,
    input signed [WIDTH-1:0] coeff3,
    output signed [(4*WIDTH)-1:0] derivative
);
    localparam EXT_WIDTH  = 4 * WIDTH;
    localparam PROD_WIDTH = 8 * WIDTH;

    wire signed [EXT_WIDTH-1:0] x_ext;
    wire signed [EXT_WIDTH-1:0] c1_ext;
    wire signed [EXT_WIDTH-1:0] c2_ext;
    wire signed [EXT_WIDTH-1:0] c3_ext;

    wire signed [PROD_WIDTH-1:0] x2_prod;
    wire signed [EXT_WIDTH-1:0]  x2;

    wire signed [EXT_WIDTH-1:0]  two_c2;
    wire signed [PROD_WIDTH-1:0] term2_prod;
    wire signed [EXT_WIDTH-1:0]  term2;

    wire signed [EXT_WIDTH-1:0]  three_c3;
    wire signed [PROD_WIDTH-1:0] term3_prod;
    wire signed [EXT_WIDTH-1:0]  term3;

    assign x_ext  = {{(3*WIDTH){x[WIDTH-1]}}, x};
    assign c1_ext = {{(3*WIDTH){coeff1[WIDTH-1]}}, coeff1};
    assign c2_ext = {{(3*WIDTH){coeff2[WIDTH-1]}}, coeff2};
    assign c3_ext = {{(3*WIDTH){coeff3[WIDTH-1]}}, coeff3};

    assign x2_prod = x_ext * x_ext;
    assign x2 = x2_prod >>> FRAC;

    assign two_c2 = c2_ext << 1;
    assign term2_prod = two_c2 * x_ext;
    assign term2 = term2_prod >>> FRAC;

    assign three_c3 = (c3_ext << 1) + c3_ext;
    assign term3_prod = three_c3 * x2;
    assign term3 = term3_prod >>> FRAC;

    assign derivative = c1_ext + term2 + term3;
endmodule