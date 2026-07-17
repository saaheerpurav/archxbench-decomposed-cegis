`timescale 1ns/1ps

module fp_fir_sample_packer #(
    parameter TAP_CNT = 101
) (
    output wire [TAP_CNT*32-1:0] sample_bus,
    input wire [31:0] s0, input wire [31:0] s1, input wire [31:0] s2,
    input wire [31:0] s3, input wire [31:0] s4, input wire [31:0] s5,
    input wire [31:0] s6, input wire [31:0] s7, input wire [31:0] s8,
    input wire [31:0] s9, input wire [31:0] s10, input wire [31:0] s11,
    input wire [31:0] s12, input wire [31:0] s13, input wire [31:0] s14,
    input wire [31:0] s15, input wire [31:0] s16, input wire [31:0] s17,
    input wire [31:0] s18, input wire [31:0] s19, input wire [31:0] s20,
    input wire [31:0] s21, input wire [31:0] s22, input wire [31:0] s23,
    input wire [31:0] s24, input wire [31:0] s25, input wire [31:0] s26,
    input wire [31:0] s27, input wire [31:0] s28, input wire [31:0] s29,
    input wire [31:0] s30, input wire [31:0] s31, input wire [31:0] s32,
    input wire [31:0] s33, input wire [31:0] s34, input wire [31:0] s35,
    input wire [31:0] s36, input wire [31:0] s37, input wire [31:0] s38,
    input wire [31:0] s39, input wire [31:0] s40, input wire [31:0] s41,
    input wire [31:0] s42, input wire [31:0] s43, input wire [31:0] s44,
    input wire [31:0] s45, input wire [31:0] s46, input wire [31:0] s47,
    input wire [31:0] s48, input wire [31:0] s49, input wire [31:0] s50,
    input wire [31:0] s51, input wire [31:0] s52, input wire [31:0] s53,
    input wire [31:0] s54, input wire [31:0] s55, input wire [31:0] s56,
    input wire [31:0] s57, input wire [31:0] s58, input wire [31:0] s59,
    input wire [31:0] s60, input wire [31:0] s61, input wire [31:0] s62,
    input wire [31:0] s63, input wire [31:0] s64, input wire [31:0] s65,
    input wire [31:0] s66, input wire [31:0] s67, input wire [31:0] s68,
    input wire [31:0] s69, input wire [31:0] s70, input wire [31:0] s71,
    input wire [31:0] s72, input wire [31:0] s73, input wire [31:0] s74,
    input wire [31:0] s75, input wire [31:0] s76, input wire [31:0] s77,
    input wire [31:0] s78, input wire [31:0] s79, input wire [31:0] s80,
    input wire [31:0] s81, input wire [31:0] s82, input wire [31:0] s83,
    input wire [31:0] s84, input wire [31:0] s85, input wire [31:0] s86,
    input wire [31:0] s87, input wire [31:0] s88, input wire [31:0] s89,
    input wire [31:0] s90, input wire [31:0] s91, input wire [31:0] s92,
    input wire [31:0] s93, input wire [31:0] s94, input wire [31:0] s95,
    input wire [31:0] s96, input wire [31:0] s97, input wire [31:0] s98,
    input wire [31:0] s99, input wire [31:0] s100
);

  assign sample_bus = {
    s100, s99, s98, s97, s96, s95, s94, s93,
    s92,  s91, s90, s89, s88, s87, s86, s85,
    s84,  s83, s82, s81, s80, s79, s78, s77,
    s76,  s75, s74, s73, s72, s71, s70, s69,
    s68,  s67, s66, s65, s64, s63, s62, s61,
    s60,  s59, s58, s57, s56, s55, s54, s53,
    s52,  s51, s50, s49, s48, s47, s46, s45,
    s44,  s43, s42, s41, s40, s39, s38, s37,
    s36,  s35, s34, s33, s32, s31, s30, s29,
    s28,  s27, s26, s25, s24, s23, s22, s21,
    s20,  s19, s18, s17, s16, s15, s14, s13,
    s12,  s11, s10, s9,  s8,  s7,  s6,  s5,
    s4,   s3,  s2,  s1,  s0
  };

endmodule