`timescale 1ns/1ps

module bandpass_mac_101 #(
    parameter DATA_W  = 20,
    parameter TAP_CNT = 101
) (
    input signed [DATA_W-1:0] x0,   input signed [DATA_W-1:0] x1,
    input signed [DATA_W-1:0] x2,   input signed [DATA_W-1:0] x3,
    input signed [DATA_W-1:0] x4,   input signed [DATA_W-1:0] x5,
    input signed [DATA_W-1:0] x6,   input signed [DATA_W-1:0] x7,
    input signed [DATA_W-1:0] x8,   input signed [DATA_W-1:0] x9,
    input signed [DATA_W-1:0] x10,  input signed [DATA_W-1:0] x11,
    input signed [DATA_W-1:0] x12,  input signed [DATA_W-1:0] x13,
    input signed [DATA_W-1:0] x14,  input signed [DATA_W-1:0] x15,
    input signed [DATA_W-1:0] x16,  input signed [DATA_W-1:0] x17,
    input signed [DATA_W-1:0] x18,  input signed [DATA_W-1:0] x19,
    input signed [DATA_W-1:0] x20,  input signed [DATA_W-1:0] x21,
    input signed [DATA_W-1:0] x22,  input signed [DATA_W-1:0] x23,
    input signed [DATA_W-1:0] x24,  input signed [DATA_W-1:0] x25,
    input signed [DATA_W-1:0] x26,  input signed [DATA_W-1:0] x27,
    input signed [DATA_W-1:0] x28,  input signed [DATA_W-1:0] x29,
    input signed [DATA_W-1:0] x30,  input signed [DATA_W-1:0] x31,
    input signed [DATA_W-1:0] x32,  input signed [DATA_W-1:0] x33,
    input signed [DATA_W-1:0] x34,  input signed [DATA_W-1:0] x35,
    input signed [DATA_W-1:0] x36,  input signed [DATA_W-1:0] x37,
    input signed [DATA_W-1:0] x38,  input signed [DATA_W-1:0] x39,
    input signed [DATA_W-1:0] x40,  input signed [DATA_W-1:0] x41,
    input signed [DATA_W-1:0] x42,  input signed [DATA_W-1:0] x43,
    input signed [DATA_W-1:0] x44,  input signed [DATA_W-1:0] x45,
    input signed [DATA_W-1:0] x46,  input signed [DATA_W-1:0] x47,
    input signed [DATA_W-1:0] x48,  input signed [DATA_W-1:0] x49,
    input signed [DATA_W-1:0] x50,  input signed [DATA_W-1:0] x51,
    input signed [DATA_W-1:0] x52,  input signed [DATA_W-1:0] x53,
    input signed [DATA_W-1:0] x54,  input signed [DATA_W-1:0] x55,
    input signed [DATA_W-1:0] x56,  input signed [DATA_W-1:0] x57,
    input signed [DATA_W-1:0] x58,  input signed [DATA_W-1:0] x59,
    input signed [DATA_W-1:0] x60,  input signed [DATA_W-1:0] x61,
    input signed [DATA_W-1:0] x62,  input signed [DATA_W-1:0] x63,
    input signed [DATA_W-1:0] x64,  input signed [DATA_W-1:0] x65,
    input signed [DATA_W-1:0] x66,  input signed [DATA_W-1:0] x67,
    input signed [DATA_W-1:0] x68,  input signed [DATA_W-1:0] x69,
    input signed [DATA_W-1:0] x70,  input signed [DATA_W-1:0] x71,
    input signed [DATA_W-1:0] x72,  input signed [DATA_W-1:0] x73,
    input signed [DATA_W-1:0] x74,  input signed [DATA_W-1:0] x75,
    input signed [DATA_W-1:0] x76,  input signed [DATA_W-1:0] x77,
    input signed [DATA_W-1:0] x78,  input signed [DATA_W-1:0] x79,
    input signed [DATA_W-1:0] x80,  input signed [DATA_W-1:0] x81,
    input signed [DATA_W-1:0] x82,  input signed [DATA_W-1:0] x83,
    input signed [DATA_W-1:0] x84,  input signed [DATA_W-1:0] x85,
    input signed [DATA_W-1:0] x86,  input signed [DATA_W-1:0] x87,
    input signed [DATA_W-1:0] x88,  input signed [DATA_W-1:0] x89,
    input signed [DATA_W-1:0] x90,  input signed [DATA_W-1:0] x91,
    input signed [DATA_W-1:0] x92,  input signed [DATA_W-1:0] x93,
    input signed [DATA_W-1:0] x94,  input signed [DATA_W-1:0] x95,
    input signed [DATA_W-1:0] x96,  input signed [DATA_W-1:0] x97,
    input signed [DATA_W-1:0] x98,  input signed [DATA_W-1:0] x99,
    input signed [DATA_W-1:0] x100,
    output signed [63:0] sum_out
);

    function signed [63:0] mul64;
        input signed [DATA_W-1:0] sample;
        input signed [15:0] coeff;
        reg signed [63:0] sample64;
        reg signed [63:0] coeff64;
        begin
            sample64 = sample;
            coeff64 = coeff;
            mul64 = sample64 * coeff64;
        end
    endfunction

    assign sum_out =
        mul64(x0,16'sd16)+mul64(x1,16'sd10)+mul64(x2,16'sd6)+mul64(x3,16'sd2)+mul64(x4,16'sd0)+
        mul64(x5,16'sd1)+mul64(x6,16'sd5)+mul64(x7,16'sd13)+mul64(x8,16'sd26)+mul64(x9,16'sd42)+
        mul64(x10,16'sd59)+mul64(x11,16'sd77)+mul64(x12,16'sd90)+mul64(x13,16'sd97)+mul64(x14,16'sd93)+
        mul64(x15,16'sd77)+mul64(x16,16'sd47)+mul64(x17,16'sd5)+mul64(x18,-16'sd45)+mul64(x19,-16'sd99)+
        mul64(x20,-16'sd149)+mul64(x21,-16'sd187)+mul64(x22,-16'sd207)+mul64(x23,-16'sd204)+
        mul64(x24,-16'sd178)+mul64(x25,-16'sd132)+mul64(x26,-16'sd73)+mul64(x27,-16'sd14)+
        mul64(x28,16'sd31)+mul64(x29,16'sd46)+mul64(x30,16'sd16)+mul64(x31,-16'sd67)+
        mul64(x32,-16'sd208)+mul64(x33,-16'sd403)+mul64(x34,-16'sd638)+mul64(x35,-16'sd891)+
        mul64(x36,-16'sd1134)+mul64(x37,-16'sd1333)+mul64(x38,-16'sd1455)+mul64(x39,-16'sd1471)+
        mul64(x40,-16'sd1359)+mul64(x41,-16'sd1111)+mul64(x42,-16'sd730)+mul64(x43,-16'sd235)+
        mul64(x44,16'sd341)+mul64(x45,16'sd955)+mul64(x46,16'sd1555)+mul64(x47,16'sd2091)+
        mul64(x48,16'sd2513)+mul64(x49,16'sd2784)+mul64(x50,16'sd2877)+mul64(x51,16'sd2784)+
        mul64(x52,16'sd2513)+mul64(x53,16'sd2091)+mul64(x54,16'sd1555)+mul64(x55,16'sd955)+
        mul64(x56,16'sd341)+mul64(x57,-16'sd235)+mul64(x58,-16'sd730)+mul64(x59,-16'sd1111)+
        mul64(x60,-16'sd1359)+mul64(x61,-16'sd1471)+mul64(x62,-16'sd1455)+mul64(x63,-16'sd1333)+
        mul64(x64,-16'sd1134)+mul64(x65,-16'sd891)+mul64(x66,-16'sd638)+mul64(x67,-16'sd403)+
        mul64(x68,-16'sd208)+mul64(x69,-16'sd67)+mul64(x70,16'sd16)+mul64(x71,16'sd46)+
        mul64(x72,16'sd31)+mul64(x73,-16'sd14)+mul64(x74,-16'sd73)+mul64(x75,-16'sd132)+
        mul64(x76,-16'sd178)+mul64(x77,-16'sd204)+mul64(x78,-16'sd207)+mul64(x79,-16'sd187)+
        mul64(x80,-16'sd149)+mul64(x81,-16'sd99)+mul64(x82,-16'sd45)+mul64(x83,16'sd5)+
        mul64(x84,16'sd47)+mul64(x85,16'sd77)+mul64(x86,16'sd93)+mul64(x87,16'sd97)+
        mul64(x88,16'sd90)+mul64(x89,16'sd77)+mul64(x90,16'sd59)+mul64(x91,16'sd42)+
        mul64(x92,16'sd26)+mul64(x93,16'sd13)+mul64(x94,16'sd5)+mul64(x95,16'sd1)+
        mul64(x96,16'sd0)+mul64(x97,16'sd2)+mul64(x98,16'sd6)+mul64(x99,16'sd10)+mul64(x100,16'sd16);

endmodule