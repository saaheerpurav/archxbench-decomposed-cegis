`timescale 1ns/1ps

module fp32_add_comb (
    input  wire [31:0] a,
    input  wire [31:0] b,
    output reg  [31:0] y
);

  reg        sa, sb, sy;
  reg [7:0]  ea, eb;
  reg [8:0]  exp_a, exp_b, exp_big, exp_small, exp_r;
  reg [27:0] sig_a, sig_b;
  reg [27:0] sig_big, sig_small, sig_small_aligned;
  reg [27:0] sig_r;
  reg [28:0] sum;
  reg [24:0] rounded;
  integer    diff;
  integer    i;

  function [27:0] shift_right_sticky;
    input [27:0] value;
    input integer sh;
    reg sticky;
    integer k;
    begin
      if (sh <= 0) begin
        shift_right_sticky = value;
      end else if (sh >= 28) begin
        shift_right_sticky = {27'd0, |value};
      end else begin
        sticky = 1'b0;
        for (k = 0; k < sh; k = k + 1)
          sticky = sticky | value[k];
        shift_right_sticky = value >> sh;
        shift_right_sticky[0] = shift_right_sticky[0] | sticky;
      end
    end
  endfunction

  always @* begin
    y = 32'h00000000;

    if (a[30:0] == 31'd0) begin
      y = b;
    end else if (b[30:0] == 31'd0) begin
      y = a;
    end else begin
      sa = a[31];
      sb = b[31];
      ea = a[30:23];
      eb = b[30:23];

      exp_a = (ea == 8'd0) ? 9'd1 : {1'b0, ea};
      exp_b = (eb == 8'd0) ? 9'd1 : {1'b0, eb};

      sig_a = {1'b0, (ea != 8'd0), a[22:0], 3'b000};
      sig_b = {1'b0, (eb != 8'd0), b[22:0], 3'b000};

      if ((exp_a > exp_b) || ((exp_a == exp_b) && (sig_a >= sig_b))) begin
        exp_big   = exp_a;
        exp_small = exp_b;
        sig_big   = sig_a;
        sig_small = sig_b;
        sy        = sa;
      end else begin
        exp_big   = exp_b;
        exp_small = exp_a;
        sig_big   = sig_b;
        sig_small = sig_a;
        sy        = sb;
      end

      diff = exp_big - exp_small;
      sig_small_aligned = shift_right_sticky(sig_small, diff);
      exp_r = exp_big;

      if (sa == sb) begin
        sum = {1'b0, sig_big} + {1'b0, sig_small_aligned};

        if (sum[27]) begin
          sig_r = sum[27:0] >> 1;
          sig_r[0] = sig_r[0] | sum[0];
          exp_r = exp_r + 9'd1;
        end else begin
          sig_r = sum[27:0];
        end
      end else begin
        sig_r = sig_big - sig_small_aligned;

        if (sig_r == 28'd0) begin
          exp_r = 9'd0;
          sy = 1'b0;
        end else begin
          for (i = 0; i < 27; i = i + 1) begin
            if ((sig_r[26] == 1'b0) && (exp_r > 9'd1)) begin
              sig_r = sig_r << 1;
              exp_r = exp_r - 9'd1;
            end
          end
        end
      end

      if (sig_r == 28'd0) begin
        y = 32'h00000000;
      end else begin
        if (sig_r[2] && (sig_r[1] || sig_r[0] || sig_r[3]))
          rounded = {1'b0, sig_r[26:3]} + 25'd1;
        else
          rounded = {1'b0, sig_r[26:3]};

        if (rounded[24]) begin
          rounded = rounded >> 1;
          exp_r = exp_r + 9'd1;
        end

        if (exp_r >= 9'd255)
          y = {sy, 8'hfe, 23'h7fffff};
        else if ((exp_r == 9'd1) && (rounded[23] == 1'b0))
          y = {sy, 8'd0, rounded[22:0]};
        else
          y = {sy, exp_r[7:0], rounded[22:0]};
      end
    end
  end

endmodule