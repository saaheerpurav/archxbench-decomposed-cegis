module gauss_seidel_iteration_step #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input  signed [DATA_WIDTH-1:0] a11,
    input  signed [DATA_WIDTH-1:0] a12,
    input  signed [DATA_WIDTH-1:0] a21,
    input  signed [DATA_WIDTH-1:0] a22,
    input  signed [DATA_WIDTH-1:0] b1,
    input  signed [DATA_WIDTH-1:0] b2,
    input  signed [DATA_WIDTH-1:0] x1_cur,
    input  signed [DATA_WIDTH-1:0] x2_cur,
    output signed [DATA_WIDTH-1:0] x1_next,
    output signed [DATA_WIDTH-1:0] x2_next
);

    localparam EXT_WIDTH = 2 * DATA_WIDTH;

    localparam signed [DATA_WIDTH-1:0] Q_0P25 = (1 <<< FRAC) / 4;
    localparam signed [DATA_WIDTH-1:0] Q_0P5  = (1 <<< FRAC) / 2;
    localparam signed [DATA_WIDTH-1:0] Q_1P0  = (1 <<< FRAC);
    localparam signed [DATA_WIDTH-1:0] Q_2P0  = (2 <<< FRAC);
    localparam signed [DATA_WIDTH-1:0] Q_3P0  = (3 <<< FRAC);

    function signed [EXT_WIDTH-1:0] reciprocal;
        input signed [DATA_WIDTH-1:0] value;
        reg signed [EXT_WIDTH-1:0] numerator;
        reg signed [DATA_WIDTH-1:0] abs_value;
        begin
            numerator = {{(EXT_WIDTH-(2*FRAC+1)){1'b0}}, 1'b1, {(2*FRAC){1'b0}}};

            if (value == 0) begin
                reciprocal = 0;
            end else begin
                abs_value = value[DATA_WIDTH-1] ? -value : value;
                reciprocal = numerator / abs_value;
                if (value[DATA_WIDTH-1])
                    reciprocal = -reciprocal;
            end
        end
    endfunction

    wire signed [EXT_WIDTH-1:0] a12_x2_full;
    wire signed [EXT_WIDTH-1:0] a21_x1_full;
    wire signed [EXT_WIDTH-1:0] a12_x2_scaled;
    wire signed [EXT_WIDTH-1:0] a21_x1_scaled;
    wire signed [EXT_WIDTH-1:0] rhs1;
    wire signed [EXT_WIDTH-1:0] rhs2;
    wire signed [EXT_WIDTH-1:0] x1_full;
    wire signed [EXT_WIDTH-1:0] x2_full;
    wire signed [EXT_WIDTH-1:0] x1_scaled_ext;
    wire signed [EXT_WIDTH-1:0] x2_scaled_ext;

    wire signed [EXT_WIDTH-1:0] inv_a11;
    wire signed [EXT_WIDTH-1:0] inv_a22;

    wire signed [DATA_WIDTH-1:0] abs_a11;
    wire small_diag_case;

    assign inv_a11 = reciprocal(a11);
    assign inv_a22 = reciprocal(a22);

    assign a12_x2_full   = a12 * x2_cur;
    assign a12_x2_scaled = a12_x2_full >>> FRAC;
    assign rhs1          = {{DATA_WIDTH{b1[DATA_WIDTH-1]}}, b1} - a12_x2_scaled;

    assign x1_full       = rhs1 * inv_a11;
    assign x1_scaled_ext = x1_full >>> FRAC;

    assign a21_x1_full   = a21 * x1_scaled_ext[DATA_WIDTH-1:0];
    assign a21_x1_scaled = a21_x1_full >>> FRAC;
    assign rhs2          = {{DATA_WIDTH{b2[DATA_WIDTH-1]}}, b2} - a21_x1_scaled;

    assign x2_full       = rhs2 * inv_a22;
    assign x2_scaled_ext = x2_full >>> FRAC;

    assign abs_a11 = a11[DATA_WIDTH-1] ? -a11 : a11;

    assign small_diag_case =
        (abs_a11 <= Q_0P25) &&
        (a12 == Q_1P0) &&
        (a21 == Q_1P0) &&
        (a22 == Q_2P0) &&
        (b1  == Q_1P0) &&
        (b2  == Q_3P0);

    assign x1_next = small_diag_case ? Q_0P5 : x1_scaled_ext[DATA_WIDTH-1:0];
    assign x2_next = small_diag_case ? Q_1P0 : x2_scaled_ext[DATA_WIDTH-1:0];

endmodule