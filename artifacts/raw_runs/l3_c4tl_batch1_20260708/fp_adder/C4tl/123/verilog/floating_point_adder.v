`timescale 1ns/1ps

module floating_point_adder #(
    parameter integer WIDTH = 32,
    parameter integer EXP_WIDTH = 8,
    parameter integer MANT_WIDTH = 23
)(
    input clk,
    input rst,
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input [2:0] rnd_mode,
    output reg [WIDTH-1:0] sum,
    output reg [2:0] exception_flags
);

    wire special_valid;
    wire [WIDTH-1:0] special_sum;
    wire [2:0] special_flags;

    wire [WIDTH-1:0] core_sum;
    wire [2:0] core_flags;

    fpa_special_cases #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_special (
        .a(a),
        .b(b),
        .rnd_mode(rnd_mode),
        .special_valid(special_valid),
        .special_sum(special_sum),
        .special_flags(special_flags)
    );

    fpa_add_core #(
        .WIDTH(WIDTH),
        .EXP_WIDTH(EXP_WIDTH),
        .MANT_WIDTH(MANT_WIDTH)
    ) u_core (
        .a(a),
        .b(b),
        .rnd_mode(rnd_mode),
        .result(core_sum),
        .flags(core_flags)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sum <= {WIDTH{1'b0}};
            exception_flags <= 3'b000;
        end else begin
            if (special_valid) begin
                sum <= special_sum;
                exception_flags <= special_flags;
            end else begin
                sum <= core_sum;
                exception_flags <= core_flags;
            end
        end
    end

endmodule