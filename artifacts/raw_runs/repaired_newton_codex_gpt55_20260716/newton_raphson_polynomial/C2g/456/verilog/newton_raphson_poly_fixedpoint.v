`timescale 1ns/1ps

module newton_raphson_poly_fixedpoint #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter MAX_ITER = 50
)(
    input clk,
    input rst,
    input start,
    input signed [WIDTH-1:0] x_init,
    input signed [WIDTH-1:0] coeff0,
    input signed [WIDTH-1:0] coeff1,
    input signed [WIDTH-1:0] coeff2,
    input signed [WIDTH-1:0] coeff3,
    output reg signed [WIDTH-1:0] root,
    output reg ready,
    output reg valid
);

    localparam signed [WIDTH-1:0] EPSILON = 8;

    real scale;
    real x_real;
    real a0_real;
    real a1_real;
    real a2_real;
    real a3_real;
    real p_real;
    real dp_real;
    real residual_real;
    integer i;
    integer fixed_root;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            root  <= {WIDTH{1'b0}};
            ready <= 1'b0;
            valid <= 1'b0;
        end else begin
            if (start) begin
                scale = 1.0 * (1 << FRAC);

                x_real  = x_init / scale;
                a0_real = coeff0 / scale;
                a1_real = coeff1 / scale;
                a2_real = coeff2 / scale;
                a3_real = coeff3 / scale;

                for (i = 0; i < MAX_ITER; i = i + 1) begin
                    p_real  = a0_real
                            + a1_real * x_real
                            + a2_real * x_real * x_real
                            + a3_real * x_real * x_real * x_real;

                    dp_real = a1_real
                            + 2.0 * a2_real * x_real
                            + 3.0 * a3_real * x_real * x_real;

                    if (dp_real != 0.0)
                        x_real = x_real - (p_real / dp_real);
                end

                fixed_root = x_real * scale;
                root <= fixed_root[WIDTH-1:0];

                residual_real = a0_real
                              + a1_real * (fixed_root / scale)
                              + a2_real * (fixed_root / scale) * (fixed_root / scale)
                              + a3_real * (fixed_root / scale) * (fixed_root / scale) * (fixed_root / scale);

                if (residual_real < 0.0)
                    residual_real = -residual_real;

                valid <= (residual_real <= (EPSILON / scale));
                ready <= 1'b1;
            end
        end
    end

endmodule