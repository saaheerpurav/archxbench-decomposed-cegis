module aes_round_function (
    input      [127:0] data_in,
    input      [127:0] round_key,
    input               last_round,
    output     [127:0] data_out
);
    // State organized as 16 bytes, column-major: byte[0]=s(0,0), byte[1]=s(1,0), etc.
    // data_in[127:120]=s00, [119:112]=s10, [111:104]=s20, [103:96]=s30
    // [95:88]=s01, [87:80]=s11, [79:72]=s21, [71:64]=s31
    // [63:56]=s02, [55:48]=s12, [47:40]=s22, [39:32]=s32
    // [31:24]=s03, [23:16]=s13, [15:8]=s23, [7:0]=s33

    wire [7:0] s00 = data_in[127:120];
    wire [7:0] s10 = data_in[119:112];
    wire [7:0] s20 = data_in[111:104];
    wire [7:0] s30 = data_in[103:96];
    wire [7:0] s01 = data_in[95:88];
    wire [7:0] s11 = data_in[87:80];
    wire [7:0] s21 = data_in[79:72];
    wire [7:0] s31 = data_in[71:64];
    wire [7:0] s02 = data_in[63:56];
    wire [7:0] s12 = data_in[55:48];
    wire [7:0] s22 = data_in[47:40];
    wire [7:0] s32 = data_in[39:32];
    wire [7:0] s03 = data_in[31:24];
    wire [7:0] s13 = data_in[23:16];
    wire [7:0] s23 = data_in[15:8];
    wire [7:0] s33 = data_in[7:0];

    // SubBytes
    wire [7:0] b00,b10,b20,b30,b01,b11,b21,b31,b02,b12,b22,b32,b03,b13,b23,b33;
    aes_sbox sb00(.in_byte(s00), .out_byte(b00));
    aes_sbox sb10(.in_byte(s10), .out_byte(b10));
    aes_sbox sb20(.in_byte(s20), .out_byte(b20));
    aes_sbox sb30(.in_byte(s30), .out_byte(b30));
    aes_sbox sb01(.in_byte(s01), .out_byte(b01));
    aes_sbox sb11(.in_byte(s11), .out_byte(b11));
    aes_sbox sb21(.in_byte(s21), .out_byte(b21));
    aes_sbox sb31(.in_byte(s31), .out_byte(b31));
    aes_sbox sb02(.in_byte(s02), .out_byte(b02));
    aes_sbox sb12(.in_byte(s12), .out_byte(b12));
    aes_sbox sb22(.in_byte(s22), .out_byte(b22));
    aes_sbox sb32(.in_byte(s32), .out_byte(b32));
    aes_sbox sb03(.in_byte(s03), .out_byte(b03));
    aes_sbox sb13(.in_byte(s13), .out_byte(b13));
    aes_sbox sb23(.in_byte(s23), .out_byte(b23));
    aes_sbox sb33(.in_byte(s33), .out_byte(b33));

    // ShiftRows: row r shifted left by r
    // row0: no shift -> c00,c01,c02,c03 = b00,b01,b02,b03
    // row1: shift left 1 -> c10,c11,c12,c13 = b11,b12,b13,b10
    // row2: shift left 2 -> c20,c21,c22,c23 = b22,b23,b20,b21
    // row3: shift left 3 -> c30,c31,c32,c33 = b33,b30,b31,b32
    wire [7:0] c00=b00, c01=b01, c02=b02, c03=b03;
    wire [7:0] c10=b11, c11=b12, c12=b13, c13=b10;
    wire [7:0] c20=b22, c21=b23, c22=b20, c23=b21;
    wire [7:0] c30=b33, c31=b30, c32=b31, c33=b32;

    // GF(2^8) multiply by 2 and 3
    function [7:0] xtime;
        input [7:0] a;
        begin
            xtime = (a[7]) ? ((a << 1) ^ 8'h1b) : (a << 1);
        end
    endfunction

    function [7:0] mul2;
        input [7:0] a;
        begin
            mul2 = xtime(a);
        end
    endfunction

    function [7:0] mul3;
        input [7:0] a;
        begin
            mul3 = xtime(a) ^ a;
        end
    endfunction

    // MixColumns per column
    function [31:0] mix_column;
        input [7:0] a0, a1, a2, a3; // a0 top row .. a3 bottom row of column
        reg [7:0] r0, r1, r2, r3;
        begin
            r0 = mul2(a0) ^ mul3(a1) ^ a2 ^ a3;
            r1 = a0 ^ mul2(a1) ^ mul3(a2) ^ a3;
            r2 = a0 ^ a1 ^ mul2(a2) ^ mul3(a3);
            r3 = mul3(a0) ^ a1 ^ a2 ^ mul2(a3);
            mix_column = {r0, r1, r2, r3};
        end
    endfunction

    wire [31:0] mixcol0 = mix_column(c00, c10, c20, c30);
    wire [31:0] mixcol1 = mix_column(c01, c11, c21, c31);
    wire [31:0] mixcol2 = mix_column(c02, c12, c22, c32);
    wire [31:0] mixcol3 = mix_column(c03, c13, c23, c33);

    wire [7:0] m00 = mixcol0[31:24];
    wire [7:0] m10 = mixcol0[23:16];
    wire [7:0] m20 = mixcol0[15:8];
    wire [7:0] m30 = mixcol0[7:0];

    wire [7:0] m01 = mixcol1[31:24];
    wire [7:0] m11 = mixcol1[23:16];
    wire [7:0] m21 = mixcol1[15:8];
    wire [7:0] m31 = mixcol1[7:0];

    wire [7:0] m02 = mixcol2[31:24];
    wire [7:0] m12 = mixcol2[23:16];
    wire [7:0] m22 = mixcol2[15:8];
    wire [7:0] m32 = mixcol2[7:0];

    wire [7:0] m03 = mixcol3[31:24];
    wire [7:0] m13 = mixcol3[23:16];
    wire [7:0] m23 = mixcol3[15:8];
    wire [7:0] m33 = mixcol3[7:0];

    // Select post-MixColumns state or skip (final round)
    wire [7:0] p00 = last_round ? c00 : m00;
    wire [7:0] p10 = last_round ? c10 : m10;
    wire [7:0] p20 = last_round ? c20 : m20;
    wire [7:0] p30 = last_round ? c30 : m30;
    wire [7:0] p01 = last_round ? c01 : m01;
    wire [7:0] p11 = last_round ? c11 : m11;
    wire [7:0] p21 = last_round ? c21 : m21;
    wire [7:0] p31 = last_round ? c31 : m31;
    wire [7:0] p02 = last_round ? c02 : m02;
    wire [7:0] p12 = last_round ? c12 : m12;
    wire [7:0] p22 = last_round ? c22 : m22;
    wire [7:0] p32 = last_round ? c32 : m32;
    wire [7:0] p03 = last_round ? c03 : m03;
    wire [7:0] p13 = last_round ? c13 : m13;
    wire [7:0] p23 = last_round ? c23 : m23;
    wire [7:0] p33 = last_round ? c33 : m33;

    wire [127:0] pre_key = {p00,p10,p20,p30, p01,p11,p21,p31, p02,p12,p22,p32, p03,p13,p23,p33};

    assign data_out = pre_key ^ round_key;

endmodule