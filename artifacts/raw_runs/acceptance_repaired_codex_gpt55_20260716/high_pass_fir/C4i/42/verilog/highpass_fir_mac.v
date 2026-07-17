`timescale 1ns/1ps

module highpass_fir_mac #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101,
    parameter ACC_W   = 64
) (
    input signed [DATA_W-1:0] sample_in,
    input signed [DATA_W-1:0] d0,  d1,  d2,  d3,  d4,  d5,  d6,  d7,  d8,  d9,
    input signed [DATA_W-1:0] d10, d11, d12, d13, d14, d15, d16, d17, d18, d19,
    input signed [DATA_W-1:0] d20, d21, d22, d23, d24, d25, d26, d27, d28, d29,
    input signed [DATA_W-1:0] d30, d31, d32, d33, d34, d35, d36, d37, d38, d39,
    input signed [DATA_W-1:0] d40, d41, d42, d43, d44, d45, d46, d47, d48, d49,
    input signed [DATA_W-1:0] d50, d51, d52, d53, d54, d55, d56, d57, d58, d59,
    input signed [DATA_W-1:0] d60, d61, d62, d63, d64, d65, d66, d67, d68, d69,
    input signed [DATA_W-1:0] d70, d71, d72, d73, d74, d75, d76, d77, d78, d79,
    input signed [DATA_W-1:0] d80, d81, d82, d83, d84, d85, d86, d87, d88, d89,
    input signed [DATA_W-1:0] d90, d91, d92, d93, d94, d95, d96, d97, d98, d99,
    output signed [ACC_W-1:0] accum
);

    function signed [ACC_W-1:0] mac_mul;
        input signed [DATA_W-1:0] x;
        input signed [15:0] c;
        begin
            mac_mul = $signed({{(ACC_W-DATA_W){x[DATA_W-1]}}, x}) *
                      $signed({{(ACC_W-16){c[15]}}, c});
        end
    endfunction

    assign accum =
        mac_mul(sample_in,  16'sd10) +
        mac_mul(d0,        16'sd17) +
        mac_mul(d1,        16'sd19) +
        mac_mul(d2,        16'sd13) +
        mac_mul(d3,        16'sd0) +
        mac_mul(d4,       -16'sd16) +
        mac_mul(d5,       -16'sd29) +
        mac_mul(d6,       -16'sd32) +
        mac_mul(d7,       -16'sd23) +
        mac_mul(d8,        16'sd0) +
        mac_mul(d9,        16'sd29) +
        mac_mul(d10,       16'sd53) +
        mac_mul(d11,       16'sd60) +
        mac_mul(d12,       16'sd42) +
        mac_mul(d13,       16'sd0) +
        mac_mul(d14,      -16'sd53) +
        mac_mul(d15,      -16'sd96) +
        mac_mul(d16,     -16'sd107) +
        mac_mul(d17,      -16'sd73) +
        mac_mul(d18,       16'sd0) +
        mac_mul(d19,       16'sd90) +
        mac_mul(d20,      16'sd161) +
        mac_mul(d21,      16'sd177) +
        mac_mul(d22,      16'sd121) +
        mac_mul(d23,       16'sd0) +
        mac_mul(d24,     -16'sd145) +
        mac_mul(d25,     -16'sd258) +
        mac_mul(d26,     -16'sd282) +
        mac_mul(d27,     -16'sd191) +
        mac_mul(d28,       16'sd0) +
        mac_mul(d29,      16'sd229) +
        mac_mul(d30,      16'sd406) +
        mac_mul(d31,      16'sd444) +
        mac_mul(d32,      16'sd301) +
        mac_mul(d33,       16'sd0) +
        mac_mul(d34,     -16'sd365) +
        mac_mul(d35,     -16'sd652) +
        mac_mul(d36,     -16'sd724) +
        mac_mul(d37,     -16'sd499) +
        mac_mul(d38,       16'sd0) +
        mac_mul(d39,      16'sd633) +
        mac_mul(d40,     16'sd1170) +
        mac_mul(d41,     16'sd1355) +
        mac_mul(d42,      16'sd989) +
        mac_mul(d43,       16'sd0) +
        mac_mul(d44,    -16'sd1511) +
        mac_mul(d45,    -16'sd3280) +
        mac_mul(d46,    -16'sd4943) +
        mac_mul(d47,    -16'sd6126) +
        mac_mul(d48,    16'sd26219) +
        mac_mul(d49,    -16'sd6126) +
        mac_mul(d50,    -16'sd4943) +
        mac_mul(d51,    -16'sd3280) +
        mac_mul(d52,    -16'sd1511) +
        mac_mul(d53,       16'sd0) +
        mac_mul(d54,      16'sd989) +
        mac_mul(d55,     16'sd1355) +
        mac_mul(d56,     16'sd1170) +
        mac_mul(d57,      16'sd633) +
        mac_mul(d58,       16'sd0) +
        mac_mul(d59,     -16'sd499) +
        mac_mul(d60,     -16'sd724) +
        mac_mul(d61,     -16'sd652) +
        mac_mul(d62,     -16'sd365) +
        mac_mul(d63,       16'sd0) +
        mac_mul(d64,      16'sd301) +
        mac_mul(d65,      16'sd444) +
        mac_mul(d66,      16'sd406) +
        mac_mul(d67,      16'sd229) +
        mac_mul(d68,       16'sd0) +
        mac_mul(d69,     -16'sd191) +
        mac_mul(d70,     -16'sd282) +
        mac_mul(d71,     -16'sd258) +
        mac_mul(d72,     -16'sd145) +
        mac_mul(d73,       16'sd0) +
        mac_mul(d74,      16'sd121) +
        mac_mul(d75,      16'sd177) +
        mac_mul(d76,      16'sd161) +
        mac_mul(d77,       16'sd90) +
        mac_mul(d78,       16'sd0) +
        mac_mul(d79,      -16'sd73) +
        mac_mul(d80,     -16'sd107) +
        mac_mul(d81,      -16'sd96) +
        mac_mul(d82,      -16'sd53) +
        mac_mul(d83,       16'sd0) +
        mac_mul(d84,       16'sd42) +
        mac_mul(d85,       16'sd60) +
        mac_mul(d86,       16'sd53) +
        mac_mul(d87,       16'sd29) +
        mac_mul(d88,       16'sd0) +
        mac_mul(d89,      -16'sd23) +
        mac_mul(d90,      -16'sd32) +
        mac_mul(d91,      -16'sd29) +
        mac_mul(d92,      -16'sd16) +
        mac_mul(d93,       16'sd0) +
        mac_mul(d94,       16'sd13) +
        mac_mul(d95,       16'sd19) +
        mac_mul(d96,       16'sd17) +
        mac_mul(d97,       16'sd10) +
        mac_mul(d98,       16'sd0) +
        mac_mul(d99,       16'sd0);

endmodule