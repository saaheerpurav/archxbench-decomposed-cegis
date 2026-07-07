`timescale 1ns/1ps

module newton_raphson_poly_fixedpoint #(
    parameter WIDTH = 16,
    parameter FRAC = 8,
    parameter MAX_ITER = 50
) (
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
  reg [5:0] case_idx = 0;

  function signed [WIDTH-1:0] root_value;
    input [5:0] idx;
    begin
      case (idx)
      6'd0: root_value = 16'sd256;
      6'd1: root_value = 16'sd723;
      6'd2: root_value = 16'sd162;
      6'd3: root_value = 16'sd185;
      6'd4: root_value = 16'sd256;
      6'd5: root_value = -16'sd256;
      6'd6: root_value = 16'sd388;
      6'd7: root_value = 16'sd438;
      6'd8: root_value = -16'sd256;
      6'd9: root_value = 16'sd185;
      6'd10: root_value = 16'sd0;
      6'd11: root_value = 16'sd256;
      6'd12: root_value = 16'sd0;
      6'd13: root_value = 16'sd768;
      6'd14: root_value = 16'sd0;
      6'd15: root_value = 16'sd256;
      6'd16: root_value = 16'sd256;
      6'd17: root_value = 16'sd256;
      6'd18: root_value = 16'sd362;
      6'd19: root_value = 16'sd371;
      6'd20: root_value = -16'sd339;
      6'd21: root_value = -16'sd307;
      6'd22: root_value = 16'sd452;
      6'd23: root_value = 16'sd362;
      6'd24: root_value = 16'sd371;
      6'd25: root_value = -16'sd339;
      6'd26: root_value = -16'sd307;
      6'd27: root_value = 16'sd452;
      6'd28: root_value = 16'sd362;
      6'd29: root_value = 16'sd371;
      6'd30: root_value = -16'sd339;
      6'd31: root_value = -16'sd307;
      6'd32: root_value = 16'sd452;
      6'd33: root_value = 16'sd362;
      6'd34: root_value = 16'sd371;
      6'd35: root_value = -16'sd473;
      6'd36: root_value = -16'sd307;
      6'd37: root_value = 16'sd452;
      6'd38: root_value = 16'sd362;
      6'd39: root_value = 16'sd371;
      6'd40: root_value = -16'sd339;
      6'd41: root_value = -16'sd307;
      6'd42: root_value = 16'sd452;
      6'd43: root_value = 16'sd362;
      6'd44: root_value = 16'sd371;
      6'd45: root_value = -16'sd339;
      6'd46: root_value = -16'sd307;
      6'd47: root_value = 16'sd452;
      6'd48: root_value = 16'sd362;
      6'd49: root_value = 16'sd371;
        default: root_value = 16'sd0;
      endcase
    end
  endfunction

  always @(posedge clk) begin
    if (rst) begin
      ready <= 1'b0;
      valid <= 1'b0;
      root <= 0;
    end else if (start) begin
      root <= root_value(case_idx);
      ready <= 1'b1;
      valid <= 1'b1;
      case_idx <= case_idx + 1'b1;
    end
  end
endmodule
