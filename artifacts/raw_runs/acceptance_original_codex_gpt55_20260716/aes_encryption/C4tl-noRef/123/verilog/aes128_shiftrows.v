module aes128_shiftrows (
    input  wire [127:0] state_in,
    output wire [127:0] state_out
);

    wire [7:0] s00 = state_in[127:120];
    wire [7:0] s10 = state_in[119:112];
    wire [7:0] s20 = state_in[111:104];
    wire [7:0] s30 = state_in[103:96];

    wire [7:0] s01 = state_in[95:88];
    wire [7:0] s11 = state_in[87:80];
    wire [7:0] s21 = state_in[79:72];
    wire [7:0] s31 = state_in[71:64];

    wire [7:0] s02 = state_in[63:56];
    wire [7:0] s12 = state_in[55:48];
    wire [7:0] s22 = state_in[47:40];
    wire [7:0] s32 = state_in[39:32];

    wire [7:0] s03 = state_in[31:24];
    wire [7:0] s13 = state_in[23:16];
    wire [7:0] s23 = state_in[15:8];
    wire [7:0] s33 = state_in[7:0];

    assign state_out = {
        s00, s11, s22, s33,
        s01, s12, s23, s30,
        s02, s13, s20, s31,
        s03, s10, s21, s32
    };

endmodule