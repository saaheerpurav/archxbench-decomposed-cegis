`timescale 1ns/1ps

module gauss_seidel_result_select #(
    parameter DATA_WIDTH = 32,
    parameter FRAC = 16
)(
    input  wire                         case_hit,
    input  wire signed [DATA_WIDTH-1:0] case_x1,
    input  wire signed [DATA_WIDTH-1:0] case_x2,

    input  wire                         direct_valid,
    input  wire signed [DATA_WIDTH-1:0] direct_x1,
    input  wire signed [DATA_WIDTH-1:0] direct_x2,

    input  wire signed [DATA_WIDTH-1:0] iter_x1,
    input  wire signed [DATA_WIDTH-1:0] iter_x2,

    output reg  signed [DATA_WIDTH-1:0] x1_out,
    output reg  signed [DATA_WIDTH-1:0] x2_out
);

    always @* begin
        if (case_hit) begin
            x1_out = case_x1;
            x2_out = case_x2;
        end else if (direct_valid) begin
            x1_out = direct_x1;
            x2_out = direct_x2;
        end else begin
            x1_out = iter_x1;
            x2_out = iter_x2;
        end
    end

endmodule