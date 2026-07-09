module aes_round (
    input      [127:0] state_in,
    input      [127:0] round_key,
    input               final_round,
    output     [127:0] state_out
);
    // State is represented as 16 bytes, byte 0 = MSB (state_in[127:120])
    // Standard AES column-major byte ordering:
    // state_in[127:120]=s00 [119:112]=s10 [111:104]=s20 [103:96]=s30
    // [95:88]=s01 [87:80]=s11 [79:72]=s21 [71:64]=s31
    // [63:56]=s02 [55:48]=s12 [47:40]=s22 [39:32]=s32
    // [31:24]=s03 [23:16]=s13 [15:8]=s23 [7:0]=s33

    wire [7:0] sb_in [0:15];
    wire [7:0] sb_out [0:15];

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : SBOX_GEN
            assign sb_in[i] = state_in[127 - i*8 -: 8];
            aes_sbox u_sbox (
                .byte_in (sb_in[i]),
                .byte_out(sb_out[i])
            );
        end
    endgenerate

    // sb_out indices correspond to bytes: 0:s00 1:s10 2:s20 3:s30
    // 4:s01 5:s11 6:s21 7:s31 8:s02 9:s12 10:s22 11:s32 12:s03 13:s13 14:s23 15:s33

    // ShiftRows: row r shifted left by r
    // row0 (s00,s01,s02,s03) -> indices 0,4,8,12  no shift
    // row1 (s10,s11,s12,s13) -> indices 1,5,9,13 shift left by1 -> (s11,s12,s13,s10)
    // row2 (s20,s21,s22,s23) -> indices 2,6,10,14 shift left by2 -> (s22,s23,s20,s21)
    // row3 (s30,s31,s32,s33) -> indices 3,7,11,15 shift left by3 -> (s33,s30,s31,s32)

    wire [7:0] sr00 = sb_out[0];
    wire [7:0] sr10 = sb_out[5];
    wire [7:0] sr20 = sb_out[10];
    wire [7:0] sr30 = sb_out[15];

    wire [7:0] sr01 = sb_out[4];
    wire [7:0] sr11 = sb_out[9];
    wire [7:0] sr21 = sb_out[14];
    wire [7:0] sr31 = sb_out[3];

    wire [7:0] sr02 = sb_out[8];
    wire [7:0] sr12 = sb_out[13];
    wire [7:0] sr22 = sb_out[2];
    wire [7:0] sr32 = sb_out[7];

    wire [7:0] sr03 = sb_out[12];
    wire [7:0] sr13 = sb_out[1];
    wire [7:0] sr23 = sb_out[6];
    wire [7:0] sr33 = sb_out[11];

    // Columns after ShiftRows
    wire [31:0] col0 = {sr00, sr10, sr20, sr30};
    wire [31:0] col1 = {sr01, sr11, sr21, sr31};
    wire [31:0] col2 = {sr02, sr12, sr22, sr32};
    wire [31:0] col3 = {sr03, sr13, sr23, sr33};

    wire [31:0] mc_col0, mc_col1, mc_col2, mc_col3;

    aes_mixcolumns u_mc0 (.col_in(col0), .col_out(mc_col0));
    aes_mixcolumns u_mc1 (.col_in(col1), .col_out(mc_col1));
    aes_mixcolumns u_mc2 (.col_in(col2), .col_out(mc_col2));
    aes_mixcolumns u_mc3 (.col_in(col3), .col_out(mc_col3));

    wire [127:0] shifted_state = {col0, col1, col2, col3};
    wire [127:0] mixed_state   = {mc_col0, mc_col1, mc_col2, mc_col3};

    wire [127:0] pre_addkey = final_round ? shifted_state : mixed_state;

    assign state_out = pre_addkey ^ round_key;

endmodule