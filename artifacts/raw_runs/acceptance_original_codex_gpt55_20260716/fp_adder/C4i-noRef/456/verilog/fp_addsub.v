`timescale 1ns/1ps

module fp_addsub #(
    parameter integer EXP_WIDTH  = 8,
    parameter integer MANT_WIDTH = 23
)(
    input  wire                   sign_big,
    input  wire                   sign_small,
    input  wire                   subtract,
    input  wire [EXP_WIDTH:0]     exp_in,
    input  wire [MANT_WIDTH+3:0]  sig_big,
    input  wire [MANT_WIDTH+3:0]  sig_small,
    output reg                    sign_out,
    output reg  [EXP_WIDTH:0]     exp_out,
    output reg  [MANT_WIDTH+4:0]  sig_out,
    output reg                    is_zero
);

    localparam integer RAW_WIDTH = MANT_WIDTH + 5;

    reg [RAW_WIDTH-1:0] big_ext;
    reg [RAW_WIDTH-1:0] small_ext;

    always @* begin
        exp_out = exp_in;

        big_ext   = {1'b0, sig_big};
        small_ext = {1'b0, sig_small};

        if (subtract) begin
            sig_out  = big_ext - small_ext;
            sign_out = sign_big;
        end else begin
            sig_out  = big_ext + small_ext;
            sign_out = sign_big;
        end

        is_zero = (sig_out == {RAW_WIDTH{1'b0}});

        if (is_zero) begin
            sign_out = 1'b0;
        end
    end

endmodule