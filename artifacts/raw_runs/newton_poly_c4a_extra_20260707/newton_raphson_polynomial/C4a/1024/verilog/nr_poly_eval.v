`timescale 1ns/1ps

module nr_poly_eval #(
    parameter WIDTH = 16,
    parameter FRAC  = 8
)(
    input  signed [WIDTH-1:0] x,
    input  signed [WIDTH-1:0] coeff0,
    input  signed [WIDTH-1:0] coeff1,
    input  signed [WIDTH-1:0] coeff2,
    input  signed [WIDTH-1:0] coeff3,
    output signed [(4*WIDTH)-1:0] poly
);

    localparam EXT  = 4 * WIDTH;
    localparam PROD = 2 * EXT;

    wire signed [EXT-1:0] x_ext;
    wire signed [EXT-1:0] c0_ext;
    wire signed [EXT-1:0] c1_ext;
    wire signed [EXT-1:0] c2_ext;
    wire signed [EXT-1:0] c3_ext;

    wire signed [EXT-1:0] h0;
    wire signed [EXT-1:0] h1;
    wire signed [EXT-1:0] h2;

    function signed [EXT-1:0] fixed_mul;
        input signed [EXT-1:0] a;
        input signed [EXT-1:0] b;
        reg signed [PROD-1:0] product;
        reg signed [PROD-1:0] scaled;
        begin
            product = a * b;
            scaled = product >>> FRAC;
            fixed_mul = scaled[EXT-1:0];
        end
    endfunction

    assign x_ext  = {{(EXT-WIDTH){x[WIDTH-1]}}, x};
    assign c0_ext = {{(EXT-WIDTH){coeff0[WIDTH-1]}}, coeff0};
    assign c1_ext = {{(EXT-WIDTH){coeff1[WIDTH-1]}}, coeff1};
    assign c2_ext = {{(EXT-WIDTH){coeff2[WIDTH-1]}}, coeff2};
    assign c3_ext = {{(EXT-WIDTH){coeff3[WIDTH-1]}}, coeff3};

    assign h0 = fixed_mul(c3_ext, x_ext) + c2_ext;
    assign h1 = fixed_mul(h0, x_ext) + c1_ext;
    assign h2 = fixed_mul(h1, x_ext) + c0_ext;

    assign poly = h2;

endmodule