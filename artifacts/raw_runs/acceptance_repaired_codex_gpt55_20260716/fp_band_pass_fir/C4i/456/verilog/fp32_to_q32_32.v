`timescale 1ns/1ps

module fp32_to_q32_32 (
    input  wire [31:0] fp,
    output reg  signed [63:0] q
);
  reg        sign;
  reg [7:0]  exp;
  reg [22:0] frac;
  reg [23:0] mant;
  reg [127:0] mag;
  integer sh;
  integer rsh;

  always @* begin
    sign = fp[31];
    exp  = fp[30:23];
    frac = fp[22:0];

    q    = 64'sd0;
    mant = 24'd0;
    mag  = 128'd0;
    sh   = 0;
    rsh  = 0;

    if (exp == 8'hff) begin
      q = sign ? 64'sh8000000000000000 : 64'sh7fffffffffffffff;
    end else begin
      if (exp == 8'd0) begin
        mant = {1'b0, frac};
        sh = -117;
      end else begin
        mant = {1'b1, frac};
        sh = exp - 118;
      end

      if (mant == 24'd0) begin
        q = 64'sd0;
      end else begin
        if (sh >= 0) begin
          if (sh >= 128)
            mag = 128'hffffffffffffffffffffffffffffffff;
          else
            mag = ({104'd0, mant} << sh);
        end else begin
          rsh = -sh;
          if (rsh >= 128)
            mag = 128'd0;
          else
            mag = ({104'd0, mant} >> rsh);
        end

        if (sign) begin
          if (mag[127:64] != 64'd0 || mag[63:0] > 64'h8000000000000000)
            q = 64'sh8000000000000000;
          else
            q = -$signed(mag[63:0]);
        end else begin
          if (mag[127:63] != 65'd0)
            q = 64'sh7fffffffffffffff;
          else
            q = $signed(mag[63:0]);
        end
      end
    end
  end
endmodule