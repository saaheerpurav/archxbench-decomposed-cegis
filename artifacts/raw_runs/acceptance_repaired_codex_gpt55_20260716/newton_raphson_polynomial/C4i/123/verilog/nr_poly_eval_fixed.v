module nr_poly_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff0,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [(4*WIDTH)-1:0] poly
);
    localparam EXT_WIDTH = 4 * WIDTH;
    localparam MUL_WIDTH = 2 * EXT_WIDTH;

    wire signed [EXT_WIDTH-1:0] x_ext;
    wire signed [EXT_WIDTH-1:0] c0_ext;
    wire signed [EXT_WIDTH-1:0] c1_ext;
    wire signed [EXT_WIDTH-1:0] c2_ext;
    wire signed [EXT_WIDTH-1:0] c3_ext;

    wire signed [EXT_WIDTH-1:0] h1;
    wire signed [EXT_WIDTH-1:0] h2;
    wire signed [EXT_WIDTH-1:0] h3;

    wire signed [MUL_WIDTH-1:0] prod1;
    wire signed [MUL_WIDTH-1:0] prod2;
    wire signed [MUL_WIDTH-1:0] prod3;

    function signed [EXT_WIDTH-1:0] round_shift_frac;
        input signed [MUL_WIDTH-1:0] value;
        reg signed [MUL_WIDTH-1:0] bias;
        begin
            bias = {{(MUL_WIDTH-FRAC){1'b0}}, 1'b1, {(FRAC-1){1'b0}}};
            if (value[MUL_WIDTH-1])
                round_shift_frac = (value - bias) >>> FRAC;
            else
                round_shift_frac = (value + bias) >>> FRAC;
        end
    endfunction

    assign x_ext  = {{(EXT_WIDTH-WIDTH){x[WIDTH-1]}}, x};
    assign c0_ext = {{(EXT_WIDTH-WIDTH){coeff0[WIDTH-1]}}, coeff0};
    assign c1_ext = {{(EXT_WIDTH-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    assign c2_ext = {{(EXT_WIDTH-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    assign c3_ext = {{(EXT_WIDTH-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    assign h1 = c3_ext;

    assign prod1 = h1 * x_ext;
    assign h2 = round_shift_frac(prod1) + c2_ext;

    assign prod2 = h2 * x_ext;
    assign h3 = round_shift_frac(prod2) + c1_ext;

    assign prod3 = h3 * x_ext;
    assign poly = round_shift_frac(prod3) + c0_ext;
endmodule