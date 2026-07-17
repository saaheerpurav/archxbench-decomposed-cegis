```verilog
module aes_mixcolumns (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);

  function [7:0] xtime;
    input [7:0] b;
    begin
      xtime = {b[6:0], 1'b0} ^ (8'h1b & {8{b[7]}});
    end
  endfunction

  function [7:0] mul2;
    input [7:0] b;
    begin
      mul2 = xtime(b);
    end
  endfunction

  function [7:0] mul3;
    input [7:0] b;
    begin
      mul3 = xtime(b) ^ b;
    end
  endfunction

  function [31:0] mix_column;
    input [31:0] col;
    reg [7:0] s0;
    reg [7:0] s1;
    reg [7:0] s2;
    reg [7:0] s3;
    reg [7:0] t0;
    reg [7:0] t1;
    reg [7:0] t2;
    reg [7:0] t3;
    begin
      s0 = col[31:24];
      s1 = col[23:16];
      s2 = col[15:8];
      s3 = col[7:0];

      t0 = mul2(s0) ^ mul3(s1) ^ s2       ^ s3;
      t1 = s0       ^ mul2(s1) ^ mul3(s2) ^ s3;
      t2 = s0       ^ s1       ^ mul2(s2) ^ mul3(s3);
      t3 = mul3(s0) ^ s1       ^ s2       ^ mul2(s3);

      mix_column = {t0, t1, t2, t3};
    end
  endfunction

  assign state_out[127:96] = mix_column(state_in[127:96]);
  assign state_out[95:64]  = mix_column(state_in[95:64]);
  assign state_out[63:32]  = mix_column(state_in[63:32]);
  assign state_out[31:0]   = mix_column(state_in[31:0]);

endmodule
```