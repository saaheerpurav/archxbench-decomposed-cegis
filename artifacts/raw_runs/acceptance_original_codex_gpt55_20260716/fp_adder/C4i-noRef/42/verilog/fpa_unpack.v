module fpa_unpack #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = 23
)(
    input  wire [WIDTH-1:0]      in,

    output wire                  sign,
    output wire [EXP_WIDTH-1:0]  exp,
    output wire [MANT_WIDTH-1:0] frac,

    output wire                  is_zero,
    output wire                  is_inf,
    output wire                  is_nan,
    output wire                  is_denorm
);

    localparam integer SIGN_BIT = WIDTH - 1;
    localparam integer EXP_MSB  = WIDTH - 2;
    localparam integer EXP_LSB  = MANT_WIDTH;

    wire exp_zero;
    wire exp_ones;
    wire frac_zero;

    assign sign = in[SIGN_BIT];
    assign exp  = in[EXP_MSB:EXP_LSB];
    assign frac = in[MANT_WIDTH-1:0];

    assign exp_zero  = (exp == {EXP_WIDTH{1'b0}});
    assign exp_ones  = (exp == {EXP_WIDTH{1'b1}});
    assign frac_zero = (frac == {MANT_WIDTH{1'b0}});

    assign is_zero   = exp_zero && frac_zero;
    assign is_denorm = exp_zero && !frac_zero;
    assign is_inf    = exp_ones && frac_zero;
    assign is_nan    = exp_ones && !frac_zero;

endmodule