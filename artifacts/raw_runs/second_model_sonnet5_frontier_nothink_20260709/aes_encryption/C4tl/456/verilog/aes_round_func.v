module aes_round_func #(
    parameter IS_LAST = 0
) (
    input      [127:0] data_in,
    input      [127:0] round_key,
    output     [127:0] data_out
);
    // State laid out as 4x4 bytes, column-major per AES spec:
    // byte order in 128-bit word: s0 s1 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 s12 s13 s14 s15
    // Standard AES state matrix indexing: state[r][c] = byte at position (c*4+r)
    // We'll treat data_in as 16 bytes b0..b15 (b0 = MSB)

    wire [7:0] b [0:15];
    genvar gi;
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : extract
            assign b[gi] = data_in[127 - gi*8 -: 8];
        end
    endgenerate

    // SubBytes
    wire [7:0] sb [0:15];
    generate
        for (gi = 0; gi < 16; gi = gi + 1) begin : subbytes
            aes_sbox sbx (.in_byte(b[gi]), .out_byte(sb[gi]));
        end
    endgenerate

    // State matrix: state[row][col] = sb[col*4+row]
    // ShiftRows: row r shifted left by r
    // row0: no shift
    // row1: shift left 1
    // row2: shift left 2
    // row3: shift left 3

    wire [7:0] s [0:3][0:3]; // s[row][col] after shiftrows

    // row 0
    assign s[0][0] = sb[0*4+0];
    assign s[0][1] = sb[1*4+0];
    assign s[0][2] = sb[2*4+0];
    assign s[0][3] = sb[3*4+0];

    // row 1 shifted left by 1
    assign s[1][0] = sb[1*4+1];
    assign s[1][1] = sb[2*4+1];
    assign s[1][2] = sb[3*4+1];
    assign s[1][3] = sb[0*4+1];

    // row 2 shifted left by 2
    assign s[2][0] = sb[2*4+2];
    assign s[2][1] = sb[3*4+2];
    assign s[2][2] = sb[0*4+2];
    assign s[2][3] = sb[1*4+2];

    // row 3 shifted left by 3
    assign s[3][0] = sb[3*4+3];
    assign s[3][1] = sb[0*4+3];
    assign s[3][2] = sb[1*4+3];
    assign s[3][3] = sb[2*4+3];

    // Build columns (32-bit) from state after shiftrows: col c = {s[0][c],s[1][c],s[2][c],s[3][c]}
    wire [31:0] col_in [0:3];
    genvar gc;
    generate
        for (gc = 0; gc < 4; gc = gc + 1) begin : cols
            assign col_in[gc] = {s[0][gc], s[1][gc], s[2][gc], s[3][gc]};
        end
    endgenerate

    wire [31:0] col_out [0:3];

    generate
        if (IS_LAST) begin : no_mix
            assign col_out[0] = col_in[0];
            assign col_out[1] = col_in[1];
            assign col_out[2] = col_in[2];
            assign col_out[3] = col_in[3];
        end else begin : mix
            aes_mixcolumns mc0 (.col_in(col_in[0]), .col_out(col_out[0]));
            aes_mixcolumns mc1 (.col_in(col_in[1]), .col_out(col_out[1]));
            aes_mixcolumns mc2 (.col_in(col_in[2]), .col_out(col_out[2]));
            aes_mixcolumns mc3 (.col_in(col_in[3]), .col_out(col_out[3]));
        end
    endgenerate

    // Reassemble 128-bit state from columns: byte order b'[col*4+row] = col_out[col][byte-within]
    wire [127:0] mixed_state;
    assign mixed_state = { col_out[0], col_out[1], col_out[2], col_out[3] };

    // AddRoundKey
    assign data_out = mixed_state ^ round_key;

endmodule