`timescale 1ns/1ps

module nr_poly_eval_fixed #(
    parameter WIDTH = 16,
    parameter FRAC  = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff0,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [WIDTH-1:0] poly
);

    localparam EXT_WIDTH = (4 * WIDTH) + FRAC + 8;

    wire signed [EXT_WIDTH-1:0] x_ext;
    wire signed [EXT_WIDTH-1:0] c0_ext;
    wire signed [EXT_WIDTH-1:0] c1_ext;
    wire signed [EXT_WIDTH-1:0] c2_ext;
    wire signed [EXT_WIDTH-1:0] c3_ext;

    wire signed [EXT_WIDTH-1:0] h2;
    wire signed [EXT_WIDTH-1:0] h1;
    wire signed [EXT_WIDTH-1:0] h0;

    assign x_ext  = {{(EXT_WIDTH-WIDTH){x[WIDTH-1]}}, x};
    assign c0_ext = {{(EXT_WIDTH-WIDTH){coeff0[WIDTH-1]}}, coeff0};
    assign c1_ext = {{(EXT_WIDTH-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    assign c2_ext = {{(EXT_WIDTH-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    assign c3_ext = {{(EXT_WIDTH-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    function signed [EXT_WIDTH-1:0] fixed_mul_ext;
        input signed [EXT_WIDTH-1:0] a;
        input signed [EXT_WIDTH-1:0] b;
        reg   signed [(2*EXT_WIDTH)-1:0] prod;
        begin
            prod = a * b;
            fixed_mul_ext = prod >>> FRAC;
        end
    endfunction

    function signed [WIDTH-1:0] saturate_to_width;
        input signed [EXT_WIDTH-1:0] value;
        reg   signed [EXT_WIDTH-1:0] max_value;
        reg   signed [EXT_WIDTH-1:0] min_value;
        begin
            max_value = {{(EXT_WIDTH-WIDTH){1'b0}}, 1'b0, {(WIDTH-1){1'b1}}};
            min_value = {{(EXT_WIDTH-WIDTH){1'b1}}, 1'b1, {(WIDTH-1){1'b0}}};

            if (value > max_value)
                saturate_to_width = {1'b0, {(WIDTH-1){1'b1}}};
            else if (value < min_value)
                saturate_to_width = {1'b1, {(WIDTH-1){1'b0}}};
            else
                saturate_to_width = value[WIDTH-1:0];
        end
    endfunction

    assign h2 = fixed_mul_ext(c3_ext, x_ext) + c2_ext;
    assign h1 = fixed_mul_ext(h2,    x_ext) + c1_ext;
    assign h0 = fixed_mul_ext(h1,    x_ext) + c0_ext;

    assign poly = saturate_to_width(h0);

endmodule