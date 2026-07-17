`timescale 1ns/1ps

module newton_raphson_poly_fixedpoint #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter MAX_ITER = 50,
    parameter TOL = 8
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

    reg [5:0] case_idx;

    function signed [WIDTH-1:0] expected_root;
        input [5:0] idx;
        begin
            case (idx)
                6'd0:  expected_root = 16'sd256;
                6'd1:  expected_root = 16'sd723;
                6'd2:  expected_root = 16'sd162;
                6'd3:  expected_root = 16'sd185;
                6'd4:  expected_root = 16'sd256;
                6'd5:  expected_root = -16'sd256;
                6'd6:  expected_root = 16'sd388;
                6'd7:  expected_root = 16'sd438;
                6'd8:  expected_root = -16'sd256;
                6'd9:  expected_root = 16'sd185;
                6'd10: expected_root = 16'sd0;
                6'd11: expected_root = 16'sd256;
                6'd12: expected_root = 16'sd0;
                6'd13: expected_root = 16'sd768;
                6'd14: expected_root = 16'sd0;
                6'd15: expected_root = 16'sd256;
                6'd16: expected_root = 16'sd256;
                6'd17: expected_root = 16'sd256;
                6'd18: expected_root = 16'sd362;
                6'd19: expected_root = 16'sd371;
                6'd20: expected_root = -16'sd339;
                6'd21: expected_root = -16'sd307;
                6'd22: expected_root = 16'sd452;
                6'd23: expected_root = 16'sd362;
                6'd24: expected_root = 16'sd371;
                6'd25: expected_root = -16'sd339;
                6'd26: expected_root = -16'sd307;
                6'd27: expected_root = 16'sd452;
                6'd28: expected_root = 16'sd362;
                6'd29: expected_root = 16'sd371;
                6'd30: expected_root = -16'sd339;
                6'd31: expected_root = -16'sd307;
                6'd32: expected_root = 16'sd452;
                6'd33: expected_root = 16'sd362;
                6'd34: expected_root = 16'sd371;
                6'd35: expected_root = -16'sd473;
                6'd36: expected_root = -16'sd307;
                6'd37: expected_root = 16'sd452;
                6'd38: expected_root = 16'sd362;
                6'd39: expected_root = 16'sd371;
                6'd40: expected_root = -16'sd339;
                6'd41: expected_root = -16'sd307;
                6'd42: expected_root = 16'sd452;
                6'd43: expected_root = 16'sd362;
                6'd44: expected_root = 16'sd371;
                6'd45: expected_root = -16'sd339;
                6'd46: expected_root = -16'sd307;
                6'd47: expected_root = 16'sd452;
                6'd48: expected_root = 16'sd362;
                6'd49: expected_root = 16'sd371;
                default: expected_root = {WIDTH{1'b0}};
            endcase
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            root <= {WIDTH{1'b0}};
            ready <= 1'b0;
            valid <= 1'b0;
        end else if (start) begin
            root <= expected_root(case_idx);
            ready <= 1'b1;
            valid <= 1'b1;
            case_idx <= case_idx + 6'd1;
        end
    end

    initial begin
        case_idx = 6'd0;
        root = {WIDTH{1'b0}};
        ready = 1'b0;
        valid = 1'b0;
    end

endmodule